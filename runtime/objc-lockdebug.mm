/*
 * Copyright (c) 2007 Apple Inc.  All Rights Reserved.
 * 
 * @APPLE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */

/***********************************************************************
* objc-lock.m
* Error-checking locks for debugging.
**********************************************************************/

#include "objc-private.h"

#if LOCKDEBUG

#include <unordered_map>


/***********************************************************************
* Lock order graph.
* "lock X precedes lock Y" means that X must be acquired first.
* This property is transitive.
**********************************************************************/

struct lockorder {
    const void *l;
    std::vector<const lockorder *> predecessors;

    mutable std::unordered_map<const lockorder *, bool> memo;

    lockorder(const void *newl) : l(newl) { }
};

static std::unordered_map<const void*, lockorder *> lockOrderList;

static objc_nodebug_lock_t lockOrderLock;


/***********************************************************************
* Recording - per-thread list of mutexes held
**********************************************************************/

enum class lockkind {
    MUTEX = 1, RDLOCK = 2, WRLOCK = 3, RECURSIVE = 4
};

#define MUTEX     lockkind::MUTEX
#define RDLOCK    lockkind::RDLOCK
#define WRLOCK    lockkind::WRLOCK
#define RECURSIVE lockkind::RECURSIVE

struct lockcount {
    lockkind k;  // the kind of lock it is (MUTEX, RDLOCK, etc)
    int i;       // the lock's nest count
};

using objc_lock_list = std::unordered_map<const void *, lockcount>;


// Thread-local list of locks owned by a thread.
// Used by lock ownership checks.
static tls_autoptr(objc_lock_list) thread_locks;

// Global list of all locks.
// Used by fork() safety check.
// This can't be a static struct because of C++ initialization order problems.
static objc_lock_list& AllLocks() {
    static objc_lock_list *locks;
    INIT_ONCE_PTR(locks, new objc_lock_list, (void)0);
    return *locks;
}

static void
destroyLocks(void *value)
{
    auto locks = (objc_lock_list *)value;
    // fixme complain about any still-held locks?
    if (locks) delete locks;
}

static objc_lock_list&
ownedLocks()
{
    return *thread_locks;
}

static bool 
hasLock(objc_lock_list& locks, const void *lock, lockkind kind)
{
    auto iter = locks.find(lock);
    if (iter != locks.end() && iter->second.k == kind) return true;
    return false;
}


static const char *sym(const void *lock)
{
    Dl_info info;
    int ok = dladdr(lock, &info);
    if (ok && info.dli_sname && info.dli_sname[0]) return info.dli_sname;
    else return "??";
}

static void 
setLock(objc_lock_list& locks, const void *lock, lockkind kind)
{
    // Check if we already own this lock.
    auto iter = locks.find(lock);
    if (iter != locks.end() && iter->second.k == kind) {
        iter->second.i++;
        return;
    }

    // Newly-acquired lock. Verify lock ordering.
    // Locks not in AllLocks are exempt (i.e. @synchronize locks)
    if (&locks != &AllLocks() && AllLocks().find(lock) != AllLocks().end()) {
        for (auto& oldlock : locks) {
            if (AllLocks().find(oldlock.first) == AllLocks().end()) {
                // oldlock is exempt
                continue;
            }

            if (lockdebug::lock_precedes_lock(lock, oldlock.first)) {
                _objc_fatal("lock %p (%s) incorrectly acquired before %p (%s)",
                            oldlock.first, sym(oldlock.first), lock, sym(lock));
            }
        }
    }

    locks[lock] = lockcount{kind, 1};
}

static void 
clearLock(objc_lock_list& locks, const void *lock, lockkind kind)
{
    auto iter = locks.find(lock);
    if (iter != locks.end()) {
        auto& l = iter->second;
        if (l.k == kind) {
            if (--l.i == 0) {
                locks.erase(iter);
            }
            return;
        }
    }

    _objc_fatal("lock not found!");
}


/***********************************************************************
* fork() safety checking
**********************************************************************/

void
lockdebug::notify::remember(objc_lock_base_t *lock)
{
    setLock(AllLocks(), lock, MUTEX);
}

void
lockdebug::notify::remember(objc_recursive_lock_base_t *lock)
{
    setLock(AllLocks(), lock, RECURSIVE);
}

void
lockdebug::assert_all_locks_locked()
{
    auto& owned = ownedLocks();

    for (const auto& l : AllLocks()) {
        if (!hasLock(owned, l.first, l.second.k)) {
            _objc_fatal("lock %p:%d is incorrectly not owned",
                        l.first, l.second.k);
        }
    }
}

void
lockdebug::assert_no_locks_locked()
{
    lockdebug::assert_no_locks_locked_except({});
}

void
lockdebug::assert_no_locks_locked_except(std::initializer_list<std::variant<void *, lock_enumerator>> canBeLocked)
{
    auto& owned = ownedLocks();

    for (const auto &l : owned) {
        // Only examine locks in AllLocks.
        if (AllLocks().find(l.first) == AllLocks().end())
            continue;

        bool thisCanBeLocked = false;
        for (auto entry : canBeLocked) {
            if (void **ptr = std::get_if<void *>(&entry)) {
                if (l.first == *ptr) {
                    thisCanBeLocked = true;
                    break;
                }
            } else if (auto enumerator = std::get_if<lock_enumerator>(&entry)) {
                for (unsigned i = 0; auto *lock = (*enumerator)(i); i++) {
                    if (l.first == lock) {
                        thisCanBeLocked = true;
                        break;
                    }
                }
            } else {
                assert(false && "Unknown variant type.");
            }
        }
        if (!thisCanBeLocked)
            _objc_fatal("lock %p:%d (%s) is incorrectly owned", l.first, l.second.k, sym(l.first));
    }
}


/***********************************************************************
* Mutex checking
**********************************************************************/

void
lockdebug::notify::lock(objc_lock_base_t *lock)
{
    auto& locks = ownedLocks();

    if (hasLock(locks, lock, MUTEX)) {
        _objc_fatal("deadlock: relocking mutex");
    }
    setLock(locks, lock, MUTEX);
}

void
lockdebug::notify::unlock(objc_lock_base_t *lock)
{
    auto& locks = ownedLocks();

    if (!hasLock(locks, lock, MUTEX)) {
        _objc_fatal("unlocking unowned mutex");
    }
    clearLock(locks, lock, MUTEX);
}


void
lockdebug::assert_locked(objc_lock_base_t *lock)
{
    auto& locks = ownedLocks();

    if (!hasLock(locks, lock, MUTEX)) {
        _objc_fatal("mutex incorrectly not locked");
    }
}

void
lockdebug::assert_unlocked(objc_lock_base_t *lock)
{
    auto& locks = ownedLocks();

    if (hasLock(locks, lock, MUTEX)) {
        _objc_fatal("mutex incorrectly locked");
    }
}


/***********************************************************************
* Recursive mutex checking
**********************************************************************/

void
lockdebug::notify::lock(objc_recursive_lock_base_t *lock)
{
    auto& locks = ownedLocks();
    setLock(locks, lock, RECURSIVE);
}

void
lockdebug::notify::unlock(objc_recursive_lock_base_t *lock)
{
    auto& locks = ownedLocks();

    if (!hasLock(locks, lock, RECURSIVE)) {
        _objc_fatal("unlocking unowned recursive mutex");
    }
    clearLock(locks, lock, RECURSIVE);
}


void
lockdebug::assert_locked(objc_recursive_lock_base_t *lock)
{
    auto& locks = ownedLocks();

    if (!hasLock(locks, lock, RECURSIVE)) {
        _objc_fatal("recursive mutex incorrectly not locked");
    }
}

void
lockdebug::assert_unlocked(objc_recursive_lock_base_t *lock)
{
    auto& locks = ownedLocks();

    if (hasLock(locks, lock, RECURSIVE)) {
        _objc_fatal("recursive mutex incorrectly locked");
    }
}


#endif
