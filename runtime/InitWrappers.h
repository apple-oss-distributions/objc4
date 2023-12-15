/*
 * Copyright (c) 2023 Apple Inc.  All Rights Reserved.
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

#ifndef INITWRAPPERS_H
#define INITWRAPPERS_H

#include <assert.h>
#include <inttypes.h>
#include <utility>
#include "objc-config.h"

namespace objc {

// We cannot use a C++ static initializer to initialize certain globals because
// libc calls us before our C++ initializers run. We also don't want a global
// pointer to some globals because of the extra indirection.
//
// ExplicitInit / LazyInit wrap doing it the hard way.
template <typename Type>
class ExplicitInit {
    alignas(Type) uint8_t _storage[sizeof(Type)];
#if DEBUG
    bool _didInit;
#endif

public:
    template <typename... Ts>
    void init(Ts &&... Args) {
        new (_storage) Type(std::forward<Ts>(Args)...);
#if DEBUG
        _didInit = true;
#endif
    }

    Type &get() {
#if DEBUG
        assert(_didInit);
#endif
        return *reinterpret_cast<Type *>(_storage);
    }
};

template <typename Type>
class LazyInit {
    alignas(Type) uint8_t _storage[sizeof(Type)];
    bool _didInit;

public:
    template <typename... Ts>
    Type *get(bool allowCreate, Ts &&... Args) {
        if (!_didInit) {
            if (!allowCreate) {
                return nullptr;
            }
            new (_storage) Type(std::forward<Ts>(Args)...);
            _didInit = true;
        }
        return reinterpret_cast<Type *>(_storage);
    }
};

} // namespace objc

#endif /* DENSEMAPEXTRAS_H */
