/*
 * Copyright (c) 1999-2008 Apple Inc.  All Rights Reserved.
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
/*
	hashtable2.m
  	Copyright 1989-1996 NeXT Software, Inc.
	Created by Bertrand Serlet, Feb 89
 */

#include "objc-private.h"
#include "hashtable2.h"

#include <string.h>

/* In order to improve efficiency, buckets contain a pointer to an array or directly the data when the array size is 1 */
typedef union {
    const void	*one;
    const void	**many;
    } oneOrMany;
    /* an optimization consists of storing directly data when count = 1 */
    
typedef struct	{
    unsigned 	count; 
    oneOrMany	elements;
    } HashBucket;
    /* private data structure; may change */
    
/*************************************************************************
 *
 *	Macros and utilities
 *	
 *************************************************************************/

#define	PTRSIZE		sizeof(void *)

#define	ALLOCTABLE()	((NXHashTable *) malloc (sizeof (NXHashTable)))
#define	ALLOCBUCKETS(nb)((HashBucket *) calloc (nb, sizeof (HashBucket)))
/* Return interior pointer so a table of classes doesn't look like objects */
#define	ALLOCPAIRS(nb) (1+(const void **) calloc (nb+1, sizeof (void *)))
#define	FREEPAIRS(p) (free((void*)(-1+p)))

#if !SUPPORT_MOD
    /* nbBuckets must be a power of 2 */
#   define BUCKETOF(table, data) (((HashBucket *)table->buckets)+((*table->prototype->hash)(table->info, data) & (table->nbBuckets-1)))
#   define GOOD_CAPACITY(c) (c <= 1 ? 1 : 1 << (log2u (c-1)+1))
#   define MORE_CAPACITY(b) (b*2)
#else
    /* iff necessary this modulo can be optimized since the nbBuckets is of the form 2**n-1 */
#   define	BUCKETOF(table, data) (((HashBucket *)table->buckets)+((*table->prototype->hash)(table->info, data) % table->nbBuckets))
#   define GOOD_CAPACITY(c) (exp2m1u (log2u (c)+1))
#   define MORE_CAPACITY(b) (b*2+1)
#endif

#define ISEQUAL(table, data1, data2) ((data1 == data2) || (*table->prototype->isEqual)(table->info, data1, data2))
	/* beware of double evaluation */
	
/*************************************************************************
 *
 *	Global data and bootstrap
 *	
 *************************************************************************/
 
static int isEqualPrototype (const void *info, const void *data1, const void *data2) {
    NXHashTablePrototype	*proto1 = (NXHashTablePrototype *) data1;
    NXHashTablePrototype	*proto2 = (NXHashTablePrototype *) data2;
    
    return (proto1->hash == proto2->hash) && (proto1->isEqual == proto2->isEqual) && (proto1->free == proto2->free) && (proto1->style == proto2->style);
    };
    
static uintptr_t hashPrototype (const void *info, const void *data) {
    NXHashTablePrototype	*proto = (NXHashTablePrototype *) data;
    
    return NXPtrHash(info, (void*)proto->hash) ^ NXPtrHash(info, (void*)proto->isEqual) ^ NXPtrHash(info, (void*)proto->free) ^ (uintptr_t) proto->style;
    };

void NXNoEffectFree (const void *info, void *data) {};

static NXHashTablePrototype protoPrototype = {
    hashPrototype, isEqualPrototype, NXNoEffectFree, 0
    };

static NXHashTable *prototypes = NULL;
	/* table of all prototypes */

static void bootstrap (void) {
    free(malloc(8));
    prototypes = ALLOCTABLE ();
    prototypes->prototype = &protoPrototype; 
    prototypes->count = 1;
    prototypes->nbBuckets = 1; /* has to be 1 so that the right bucket is 0 */
    prototypes->buckets = ALLOCBUCKETS(1);
    prototypes->info = NULL;
    ((HashBucket *) prototypes->buckets)[0].count = 1;
    ((HashBucket *) prototypes->buckets)[0].elements.one = &protoPrototype;
    };

int NXPtrIsEqual (const void *info, const void *data1, const void *data2) {
    return data1 == data2;
    };

/*************************************************************************
 *
 *	On z'y va
 *	
 *************************************************************************/

NXHashTable *NXCreateHashTableFromZone (NXHashTablePrototype prototype, unsigned capacity, const void *info, void *) {
    return NXCreateHashTable(prototype, capacity, info);
}

NXHashTable *NXCreateHashTable (NXHashTablePrototype prototype, unsigned capacity, const void *info) {
    NXHashTable			*table;
    NXHashTablePrototype	*proto;
    
    table = ALLOCTABLE();
    if (! prototypes) bootstrap ();
    if (! prototype.hash) prototype.hash = NXPtrHash;
    if (! prototype.isEqual) prototype.isEqual = NXPtrIsEqual;
    if (! prototype.free) prototype.free = NXNoEffectFree;
    if (prototype.style) {
	_objc_inform ("*** NXCreateHashTable: invalid style\n");
	return NULL;
	};
    proto = (NXHashTablePrototype *)NXHashGet (prototypes, &prototype); 
    if (! proto) {
        proto
        = (NXHashTablePrototype *) malloc(sizeof (NXHashTablePrototype));
        *proto = prototype;
        (void) NXHashInsert (prototypes, proto);
        proto = (NXHashTablePrototype *)NXHashGet (prototypes, &prototype);
        if (! proto) {
            _objc_inform ("*** NXCreateHashTable: bug\n");
            return NULL;
        };
	};
    table->prototype = proto; table->count = 0; table->info = info;
    table->nbBuckets = GOOD_CAPACITY(capacity);
    table->buckets = ALLOCBUCKETS(table->nbBuckets);
    return table;
    }

static void freeBucketPairs (void (*freeProc)(const void *info, void *data), HashBucket bucket, const void *info) {
    unsigned	j = bucket.count;
    const void	**pairs;
    
    if (j == 1) {
	(*freeProc) (info, (void *) bucket.elements.one);
	return;
	};
    pairs = bucket.elements.many;
    while (j--) {
	(*freeProc) (info, (void *) *pairs);
	pairs ++;
	};
    FREEPAIRS (bucket.elements.many);
    };
    
static void freeBuckets (NXHashTable *table, int freeObjects) {
    unsigned		i = table->nbBuckets;
    HashBucket		*buckets = (HashBucket *) table->buckets;
    
    while (i--) {
	if (buckets->count) {
	    freeBucketPairs ((freeObjects) ? table->prototype->free : NXNoEffectFree, *buckets, table->info);
	    buckets->count = 0;
	    buckets->elements.one = NULL;
	    };
	buckets++;
	};
    };
    
void NXFreeHashTable (NXHashTable *table) {
    freeBuckets (table, YES);
    free (table->buckets);
    free (table);
    };
    
void NXEmptyHashTable (NXHashTable *table) {
    freeBuckets (table, NO);
    table->count = 0;
    }

void NXResetHashTable (NXHashTable *table) {
    freeBuckets (table, YES);
    table->count = 0;
}

BOOL NXCompareHashTables (NXHashTable *table1, NXHashTable *table2) {
    if (table1 == table2) return YES;
    if (NXCountHashTable (table1) != NXCountHashTable (table2)) return NO;
    else {
	void		*data;
	NXHashState	state = NXInitHashState (table1);
	while (NXNextHashState (table1, &state, &data)) {
	    if (! NXHashMember (table2, data)) return NO;
	}
	return YES;
    }
}

NXHashTable *NXCopyHashTable (NXHashTable *table) {
    NXHashTable		*newt;
    NXHashState		state = NXInitHashState (table);
    void		*data;
    
    newt = ALLOCTABLE();
    newt->prototype = table->prototype; newt->count = 0;
    newt->info = table->info;
    newt->nbBuckets = table->nbBuckets;
    newt->buckets = ALLOCBUCKETS(newt->nbBuckets);
    while (NXNextHashState (table, &state, &data))
        NXHashInsert (newt, data);
    return newt;
    }

unsigned NXCountHashTable (NXHashTable *table) {
    return table->count;
    }

int NXHashMember (NXHashTable *table, const void *data) {
    HashBucket	*bucket = BUCKETOF(table, data);
    unsigned	j = bucket->count;
    const void	**pairs;
    
    if (! j) return 0;
    if (j == 1) {
    	return ISEQUAL(table, data, bucket->elements.one);
	};
    pairs = bucket->elements.many;
    while (j--) {
	/* we don't cache isEqual because lists are short */
    	if (ISEQUAL(table, data, *pairs)) return 1; 
	pairs ++;
	};
    return 0;
    }

void *NXHashGet (NXHashTable *table, const void *data) {
    HashBucket	*bucket = BUCKETOF(table, data);
    unsigned	j = bucket->count;
    const void	**pairs;
    
    if (! j) return NULL;
    if (j == 1) {
    	return ISEQUAL(table, data, bucket->elements.one)
	    ? (void *) bucket->elements.one : NULL; 
	};
    pairs = bucket->elements.many;
    while (j--) {
	/* we don't cache isEqual because lists are short */
    	if (ISEQUAL(table, data, *pairs)) return (void *) *pairs; 
	pairs ++;
	};
    return NULL;
    }

unsigned _NXHashCapacity (NXHashTable *table) {
    return table->nbBuckets;
    }

void _NXHashRehashToCapacity (NXHashTable *table, unsigned newCapacity) {
    /* Rehash: we create a pseudo table pointing really to the old guys,
    extend self, copy the old pairs, and free the pseudo table */
    NXHashTable	*old;
    NXHashState	state;
    void	*aux;
    
    old = ALLOCTABLE();
    old->prototype = table->prototype; old->count = table->count; 
    old->nbBuckets = table->nbBuckets; old->buckets = table->buckets;
    table->nbBuckets = newCapacity;
    table->count = 0; table->buckets = ALLOCBUCKETS(table->nbBuckets);
    state = NXInitHashState (old);
    while (NXNextHashState (old, &state, &aux))
	(void) NXHashInsert (table, aux);
    freeBuckets (old, NO);
    if (old->count != table->count)
	_objc_inform("*** hashtable: count differs after rehashing; probably indicates a broken invariant: there are x and y such as isEqual(x, y) is TRUE but hash(x) != hash (y)\n");
    free (old->buckets); 
    free (old);
    }

static void _NXHashRehash (NXHashTable *table) {
    _NXHashRehashToCapacity (table, MORE_CAPACITY(table->nbBuckets));
    }

void *NXHashInsert (NXHashTable *table, const void *data) {
    HashBucket	*bucket = BUCKETOF(table, data);
    unsigned	j = bucket->count;
    const void	**pairs;
    const void	**newt;
    
    if (! j) {
	bucket->count++; bucket->elements.one = data; 
	table->count++; 
	return NULL;
	};
    if (j == 1) {
    	if (ISEQUAL(table, data, bucket->elements.one)) {
	    const void	*old = bucket->elements.one;
	    bucket->elements.one = data;
	    return (void *) old;
	    };
	newt = ALLOCPAIRS(2);
	newt[1] = bucket->elements.one;
	*newt = data;
	bucket->count++; bucket->elements.many = newt; 
	table->count++; 
	if (table->count > table->nbBuckets) _NXHashRehash (table);
	return NULL;
	};
    pairs = bucket->elements.many;
    while (j--) {
	/* we don't cache isEqual because lists are short */
    	if (ISEQUAL(table, data, *pairs)) {
	    const void	*old = *pairs;
	    *pairs = data;
	    return (void *) old;
	    };
	pairs ++;
	};
    /* we enlarge this bucket; and put new data in front */
    newt = ALLOCPAIRS(bucket->count+1);
    if (bucket->count) memmove ((char*)(newt+1), (const char*)bucket->elements.many, bucket->count * PTRSIZE);
    *newt = data;
    FREEPAIRS (bucket->elements.many);
    bucket->count++; bucket->elements.many = newt; 
    table->count++; 
    if (table->count > table->nbBuckets) _NXHashRehash (table);
    return NULL;
    }

void *NXHashInsertIfAbsent (NXHashTable *table, const void *data) {
    HashBucket	*bucket = BUCKETOF(table, data);
    unsigned	j = bucket->count;
    const void	**pairs;
    const void	**newt;
    
    if (! j) {
	bucket->count++; bucket->elements.one = data; 
	table->count++; 
	return (void *) data;
	};
    if (j == 1) {
    	if (ISEQUAL(table, data, bucket->elements.one))
	    return (void *) bucket->elements.one;
	newt = ALLOCPAIRS(2);
	newt[1] = bucket->elements.one;
	*newt = data;
	bucket->count++; bucket->elements.many = newt; 
	table->count++; 
	if (table->count > table->nbBuckets) _NXHashRehash (table);
	return (void *) data;
	};
    pairs = bucket->elements.many;
    while (j--) {
	/* we don't cache isEqual because lists are short */
    	if (ISEQUAL(table, data, *pairs))
	    return (void *) *pairs;
	pairs ++;
	};
    /* we enlarge this bucket; and put new data in front */
    newt = ALLOCPAIRS(bucket->count+1);
    if (bucket->count) memmove ((char*)(newt+1), (const char*)bucket->elements.many, bucket->count * PTRSIZE);
    *newt = data;
    FREEPAIRS (bucket->elements.many);
    bucket->count++; bucket->elements.many = newt; 
    table->count++; 
    if (table->count > table->nbBuckets) _NXHashRehash (table);
    return (void *) data;
    }

void *NXHashRemove (NXHashTable *table, const void *data) {
    HashBucket	*bucket = BUCKETOF(table, data);
    unsigned	j = bucket->count;
    const void	**pairs;
    const void	**newt;
    
    if (! j) return NULL;
    if (j == 1) {
	if (! ISEQUAL(table, data, bucket->elements.one)) return NULL;
	data = bucket->elements.one;
	table->count--; bucket->count--; bucket->elements.one = NULL;
	return (void *) data;
	};
    pairs = bucket->elements.many;
    if (j == 2) {
    	if (ISEQUAL(table, data, pairs[0])) {
	    bucket->elements.one = pairs[1]; data = pairs[0];
	    }
	else if (ISEQUAL(table, data, pairs[1])) {
	    bucket->elements.one = pairs[0]; data = pairs[1];
	    }
	else return NULL;
	FREEPAIRS (pairs);
	table->count--; bucket->count--;
	return (void *) data;
	};
    while (j--) {
    	if (ISEQUAL(table, data, *pairs)) {
	    data = *pairs;
	    /* we shrink this bucket */
	    newt = (bucket->count-1) 
		? ALLOCPAIRS(bucket->count-1) : NULL;
	    if (bucket->count-1 != j)
		    memmove ((char*)newt, (const char*)bucket->elements.many, PTRSIZE*(bucket->count-j-1));
	    if (j)
		    memmove ((char*)(newt+bucket->count-j-1), (const char*)(bucket->elements.many + bucket->count-j), PTRSIZE*j);
	    FREEPAIRS (bucket->elements.many);
	    table->count--; bucket->count--; bucket->elements.many = newt;
	    return (void *) data;
	    };
	pairs ++;
	};
    return NULL;
    }

NXHashState NXInitHashState (NXHashTable *table) {
    NXHashState	state;
    
    state.i = table->nbBuckets;
    state.j = 0;
    return state;
    };
    
int NXNextHashState (NXHashTable *table, NXHashState *state, void **data) {
    HashBucket		*buckets = (HashBucket *) table->buckets;
    
    while (state->j == 0) {
	if (state->i == 0) return NO;
	state->i--; state->j = buckets[state->i].count;
	}
    state->j--;
    buckets += state->i;
    *data = (void *) ((buckets->count == 1) 
    		? buckets->elements.one : buckets->elements.many[state->j]);
    return YES;
    };

/*************************************************************************
 *
 *	Conveniences
 *	
 *************************************************************************/

uintptr_t NXPtrHash (const void *info, const void *data) {
    return (((uintptr_t) data) >> 16) ^ ((uintptr_t) data);
    };
    
uintptr_t NXStrHash (const void *info, const void *data) {
    uintptr_t	hash = 0;
    unsigned char	*s = (unsigned char *) data;
    /* unsigned to avoid a sign-extend */
    /* unroll the loop */
    if (s) for (; ; ) { 
	if (*s == '\0') break;
	hash ^= (uintptr_t) *s++;
	if (*s == '\0') break;
	hash ^= (uintptr_t) *s++ << 8;
	if (*s == '\0') break;
	hash ^= (uintptr_t) *s++ << 16;
	if (*s == '\0') break;
	hash ^= (uintptr_t) *s++ << 24;
	}
    return hash;
    };
    
int NXStrIsEqual (const void *info, const void *data1, const void *data2) {
    if (data1 == data2) return YES;
    if (! data1) return ! strlen ((char *) data2);
    if (! data2) return ! strlen ((char *) data1);
    if (((char *) data1)[0] != ((char *) data2)[0]) return NO;
    return (strcmp ((char *) data1, (char *) data2)) ? NO : YES;
    };
    
void NXReallyFree (const void *info, void *data) {
    free (data);
    };

/* All the following functions are really private, made non-static only for the benefit of shlibs */
static uintptr_t hashPtrStructKey (const void *info, const void *data) {
    return NXPtrHash(info, *((void **) data));
    };

static int isEqualPtrStructKey (const void *info, const void *data1, const void *data2) {
    return NXPtrIsEqual (info, *((void **) data1), *((void **) data2));
    };

static uintptr_t hashStrStructKey (const void *info, const void *data) {
    return NXStrHash(info, *((char **) data));
    };

static int isEqualStrStructKey (const void *info, const void *data1, const void *data2) {
    return NXStrIsEqual (info, *((char **) data1), *((char **) data2));
    };

const NXHashTablePrototype NXPtrPrototype = {
    NXPtrHash, NXPtrIsEqual, NXNoEffectFree, 0
    };

const NXHashTablePrototype NXStrPrototype = {
    NXStrHash, NXStrIsEqual, NXNoEffectFree, 0
    };

const NXHashTablePrototype NXPtrStructKeyPrototype = {
    hashPtrStructKey, isEqualPtrStructKey, NXReallyFree, 0
    };

const NXHashTablePrototype NXStrStructKeyPrototype = {
    hashStrStructKey, isEqualStrStructKey, NXReallyFree, 0
    };
