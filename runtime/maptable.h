/*
 * Copyright (c) 1999-2003, 2006-2007 Apple Inc.  All Rights Reserved.
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
/*	maptable.h
	Scalable hash table of mappings.
	Bertrand, August 1990
	Copyright 1990-1996 NeXT Software, Inc.
*/

#ifndef _OBJC_MAPTABLE_H_
#define _OBJC_MAPTABLE_H_

#ifndef _OBJC_PRIVATE_H_
#   define OBJC_MAP_AVAILABILITY \
    OBJC_OSX_DEPRECATED_OTHERS_UNAVAILABLE(10.0, 10.1, "NXMapTable is deprecated")
#else
#   define OBJC_MAP_AVAILABILITY
#endif

#include <objc/objc.h>

#if __has_feature(ptrauth_calls)
#include <ptrauth.h>

__BEGIN_DECLS

#define NXMapTable_ptrauth_prototype \
    __ptrauth(ptrauth_key_process_independent_data, 1, \
    ptrauth_string_discriminator("_NXMapTable::prototype"))
#define NXMapTable_ptrauth_hash \
    __ptrauth(ptrauth_key_process_independent_code, 1, \
    ptrauth_string_discriminator("_NXMapTablePrototype::hash"))
#define NXMapTable_ptrauth_isEqual \
    __ptrauth(ptrauth_key_process_independent_code, 1, \
    ptrauth_string_discriminator("_NXMapTablePrototype::isEqual"))
#define NXMapTable_ptrauth_free \
    __ptrauth(ptrauth_key_process_independent_code, 1, \
    ptrauth_string_discriminator("_NXMapTablePrototype::free"))
#else
__BEGIN_DECLS

#define NXMapTable_ptrauth_prototype
#define NXMapTable_ptrauth_hash
#define NXMapTable_ptrauth_isEqual
#define NXMapTable_ptrauth_free
#endif

/***************	Definitions		***************/

    /* This module allows hashing of arbitrary associations [key -> value].  Keys and values must be pointers or integers, and client is responsible for allocating/deallocating this data.  A deallocation call-back is provided.
    NX_MAPNOTAKEY (-1) is used internally as a marker, and therefore keys must always be different from -1.
    As well-behaved scalable data structures, hash tables double in size when they start becoming full, thus guaranteeing both average constant time access and linear size. */

typedef struct _NXMapTable {
    /* private data structure; may change */
    const struct _NXMapTablePrototype	* NXMapTable_ptrauth_prototype _Nonnull prototype;
    unsigned	count;
    unsigned	nbBucketsMinusOne;
    void	* _Nullable buckets;
} NXMapTable OBJC_MAP_AVAILABILITY;

typedef struct OBJC_MAP_AVAILABILITY _NXMapTablePrototype {
    unsigned	(* NXMapTable_ptrauth_hash _Nonnull hash)(NXMapTable * _Nonnull,
                                                          const void * _Nullable key);
    int		(* NXMapTable_ptrauth_isEqual _Nonnull isEqual)(NXMapTable * _Nonnull,
                                                            const void * _Nullable key1,
                                                            const void * _Nullable key2);
    void	(* NXMapTable_ptrauth_free _Nonnull free)(NXMapTable * _Nonnull,
                                                      void * _Nullable key,
                                                      void * _Nullable value);
    int		style; /* reserved for future expansion; currently 0 */
} NXMapTablePrototype OBJC_MAP_AVAILABILITY;
    
    /* invariants assumed by the implementation: 
	A - key != -1
	B - key1 == key2 => hash(key1) == hash(key2)
	    when key varies over time, hash(key) must remain invariant
	    e.g. if string key, the string must not be changed
	C - isEqual(key1, key2) => key1 == key2
    */

#define NX_MAPNOTAKEY	((void * _Nonnull)(-1))

/***************	Functions		***************/

OBJC_EXPORT NXMapTable * _Nonnull
NXCreateMapTableFromZone(NXMapTablePrototype prototype,
                         unsigned capacity, void * _Nullable zone __unused)
    OBJC_MAP_AVAILABILITY;

OBJC_EXPORT NXMapTable * _Nonnull
NXCreateMapTable(NXMapTablePrototype prototype, unsigned capacity)
    OBJC_MAP_AVAILABILITY;
    /* capacity is only a hint; 0 creates a small table */

OBJC_EXPORT void
NXFreeMapTable(NXMapTable * _Nonnull table)
    OBJC_MAP_AVAILABILITY;
    /* call free for each pair, and recovers table */
	
OBJC_EXPORT void
NXResetMapTable(NXMapTable * _Nonnull table)
    OBJC_MAP_AVAILABILITY;
    /* free each pair; keep current capacity */

OBJC_EXPORT BOOL
NXCompareMapTables(NXMapTable * _Nonnull table1, NXMapTable * _Nonnull table2)
    OBJC_MAP_AVAILABILITY;
    /* Returns YES if the two sets are equal (each member of table1 in table2, and table have same size) */

OBJC_EXPORT unsigned
NXCountMapTable(NXMapTable * _Nonnull table)
    OBJC_MAP_AVAILABILITY;
    /* current number of data in table */
	
OBJC_EXPORT void * _Nullable
NXMapMember(NXMapTable * _Nonnull table, const void * _Nullable key,
            void * _Nullable * _Nonnull value) OBJC_MAP_AVAILABILITY;
    /* return original table key or NX_MAPNOTAKEY.  If key is found, value is set */
	
OBJC_EXPORT void * _Nullable
NXMapGet(NXMapTable * _Nonnull table, const void * _Nullable key)
    OBJC_MAP_AVAILABILITY;
    /* return original corresponding value or NULL.  When NULL need be stored as value, NXMapMember can be used to test for presence */

OBJC_EXPORT void * _Nullable
NXMapGetWithHash(NXMapTable * _Nonnull table, const void * _Nullable key, unsigned hash)
    OBJC_MAP_AVAILABILITY;
    /* Like NXMapGet, except the hash is passed in by the caller. The value MUST match what's returned by the table's hash callback. This allows callers that also need the hash to avoid computing it twice. */

OBJC_EXPORT void * _Nullable
NXMapInsert(NXMapTable * _Nonnull table, const void * _Nullable key,
            const void * _Nullable value)
    OBJC_MAP_AVAILABILITY;
    /* override preexisting pair; Return previous value or NULL. */

OBJC_EXPORT void * _Nullable
NXMapInsertWithHash(NXMapTable * _Nonnull table, const void * _Nullable key,
                    unsigned hash, const void * _Nullable value)
    OBJC_MAP_AVAILABILITY;
    /* Like NXMapInsert, except the hash is passed in by the caller. The value MUST match what's returned by the table's hash callback. This allows callers that also need the hash to avoid computing it twice. */

OBJC_EXPORT void * _Nullable
NXMapRemove(NXMapTable * _Nonnull table, const void * _Nullable key)
    OBJC_MAP_AVAILABILITY;
    /* previous value or NULL is returned */
	
/* Iteration over all elements of a table consists in setting up an iteration state and then to progress until all entries have been visited.  An example of use for counting elements in a table is:
    unsigned	count = 0;
    const MyKey	*key;
    const MyValue	*value;
    NXMapState	state = NXInitMapState(table);
    while(NXNextMapState(table, &state, &key, &value)) {
	count++;
    }
*/

typedef struct {int index;} NXMapState OBJC_MAP_AVAILABILITY;
    /* callers should not rely on actual contents of the struct */

OBJC_EXPORT NXMapState
NXInitMapState(NXMapTable * _Nonnull table)
    OBJC_MAP_AVAILABILITY;

OBJC_EXPORT int
NXNextMapState(NXMapTable * _Nonnull table, NXMapState * _Nonnull state,
               const void * _Nullable * _Nonnull key,
               const void * _Nullable * _Nonnull value)
    OBJC_MAP_AVAILABILITY;
    /* returns 0 when all elements have been visited */

/***************	Conveniences		***************/

OBJC_EXPORT const NXMapTablePrototype NXPtrValueMapPrototype
    OBJC_MAP_AVAILABILITY;
    /* hashing is pointer/integer hashing;
      isEqual is identity;
      free is no-op. */
OBJC_EXPORT const NXMapTablePrototype NXStrValueMapPrototype
    OBJC_MAP_AVAILABILITY;
    /* hashing is string hashing;
      isEqual is strcmp;
      free is no-op. */

__END_DECLS

#endif /* _OBJC_MAPTABLE_H_ */
