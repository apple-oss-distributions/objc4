/*
 * Copyright (c) 2017 Apple Inc.  All Rights Reserved.
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
* objc-locks.h
* Declarations of all locks used in the runtime.
**********************************************************************/

#ifndef _OBJC_LOCKS_H
#define _OBJC_LOCKS_H

#include "objc-config.h"
#include "InitWrappers.h"

// fork() safety requires careful tracking of all locks used in the runtime.
// Thou shalt not declare any locks outside this file.

// Lock ordering is declared in _objc_fork_prepare()
// and is enforced by lockdebug.

// ExplicitInit wrapper around a lock. Convertible to the underlying lock type
// and forwards basic lock/unlock.
template <typename Lock>
class ExplicitInitLock: public objc::ExplicitInit<Lock> {
public:
    operator Lock &() {
        return this->get();
    }

    void lock() {
        this->get().lock();
    }

    void unlock() {
        this->get().unlock();
    }

    void reset() {
        this->get().reset();
    }

    bool tryLock() {
        return this->get().tryLock();
    }
};


extern ExplicitInitLock<mutex_t> classInitLock;
extern ExplicitInitLock<mutex_t> pendingInitializeMapLock;
extern ExplicitInitLock<mutex_t> selLock;
#if CONFIG_USE_CACHE_LOCK
extern ExplicitInitLock<mutex_t> cacheUpdateLock;
#endif
extern ExplicitInitLock<recursive_mutex_t> loadMethodLock;
extern ExplicitInitLock<mutex_t> crashlog_lock;
extern ExplicitInitLock<spinlock_t> objcMsgLogLock;
extern ExplicitInitLock<mutex_t> AltHandlerDebugLock;
extern ExplicitInitLock<mutex_t> AssociationsManagerLock;
extern objc::ExplicitInit<StripedMap<spinlock_t>> PropertyLocks;
extern objc::ExplicitInit<StripedMap<spinlock_t>> StructLocks;
extern objc::ExplicitInit<StripedMap<spinlock_t>> CppObjectLocks;
extern ExplicitInitLock<mutex_t> runtimeLock;
extern ExplicitInitLock<mutex_t> DemangleCacheLock;

// SideTable lock is buried awkwardly. Call a function to manipulate it.
extern void SideTableLockAll();
extern void SideTableUnlockAll();
extern void SideTableForceResetAll();
extern spinlock_t *SideTableGetLock(unsigned n);

#endif
