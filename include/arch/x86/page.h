/*
 * Copyright © 2020 Amazon.com, Inc. or its affiliates.
 * All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#ifndef KTF_PAGE_H
#define KTF_PAGE_H

#include <compiler.h>

#define PAGE_SHIFT    12
#define PAGE_SIZE     (_U64(1) << PAGE_SHIFT)
#define PAGE_MASK     (~(PAGE_SIZE - 1))
#define PAGE_ORDER_4K 0

#define PAGE_SHIFT_2M 21
#define PAGE_SIZE_2M  (_U64(1) << PAGE_SHIFT_2M)
#define PAGE_MASK_2M  (~(PAGE_SIZE_2M - 1))
#define PAGE_ORDER_2M 9

#define PAGE_SHIFT_1G 30
#define PAGE_SIZE_1G  (_U64(1) << PAGE_SHIFT_1G)
#define PAGE_MASK_1G  (~(PAGE_SIZE_1G - 1))
#define PAGE_ORDER_1G 18

#define MAX_PAGE_ORDER     PAGE_ORDER_1G
#define PAGE_ORDER_INVALID (-1)

#define PAGE_ORDER_TO_MASK(order) (~((PAGE_SIZE << (order)) - 1))

#define _PAGE_PRESENT  0x0001
#define _PAGE_RW       0x0002
#define _PAGE_USER     0x0004
#define _PAGE_PWT      0x0008
#define _PAGE_PCD      0x0010
#define _PAGE_ACCESSED 0x0020
#define _PAGE_DIRTY    0x0040
#define _PAGE_AD       (_PAGE_ACCESSED | _PAGE_DIRTY)
#define _PAGE_PSE      0x0080
#define _PAGE_PAT      0x0080
#define _PAGE_GLOBAL   0x0100
#define _PAGE_AVAIL    0x0e00
#define _PAGE_PSE_PAT  0x1000
#define _PAGE_NX       (_U64(1) << 63)

#define _PAGE_ALL_FLAGS                                                                  \
    (_PAGE_PRESENT | _PAGE_RW | _PAGE_USER | _PAGE_PWT | _PAGE_PCD | _PAGE_AD |          \
     _PAGE_PAT | _PAGE_GLOBAL | _PAGE_PSE_PAT | _PAGE_NX)

#define PTE_FLAGS(...) (TOKEN_OR(_PAGE_, ##__VA_ARGS__))

#define PT_NO_FLAGS 0

#define L1_PROT              (_PAGE_PRESENT | _PAGE_RW | _PAGE_ACCESSED | _PAGE_DIRTY)
#define L1_PROT_GLOB         (L1_PROT | _PAGE_GLOBAL)
#define L1_PROT_RO           (_PAGE_PRESENT | _PAGE_ACCESSED)
#define L1_PROT_RO_GLOB      (L1_PROT_RO | _PAGE_GLOBAL)
#define L1_PROT_NOCACHE      (L1_PROT | _PAGE_PCD)
#define L1_PROT_NOCACHE_GLOB (L1_PROT_NOCACHE | _PAGE_GLOBAL)
#define L1_PROT_USER         (L1_PROT | _PAGE_USER)
#define L1_PROT_USER_RO      (L1_PROT_RO | _PAGE_USER)

#define L2_PROT         (L1_PROT | _PAGE_DIRTY)
#define L2_PROT_RO      (L1_PROT_RO | _PAGE_DIRTY)
#define L2_PROT_USER    (L2_PROT | _PAGE_USER)
#define L2_PROT_USER_RO (L2_PROT_RO | _PAGE_USER)

#define L3_PROT         (L2_PROT | _PAGE_DIRTY)
#define L3_PROT_RO      (L2_PROT_RO | _PAGE_DIRTY)
#define L3_PROT_USER    (L3_PROT | _PAGE_USER)
#define L3_PROT_USER_RO (L3_PROT_RO | _PAGE_USER)

#define L4_PROT         (L3_PROT | _PAGE_DIRTY)
#define L4_PROT_RO      (L3_PROT_RO | _PAGE_DIRTY)
#define L4_PROT_USER    (L4_PROT | _PAGE_USER)
#define L4_PROT_USER_RO (L4_PROT_RO | _PAGE_USER)

#define PTE_ORDER 3
#define PTE_SIZE  (_U32(1) << PTE_ORDER)

#define PT_ORDER    9
#define L1_PT_SHIFT PAGE_SHIFT
#define L2_PT_SHIFT (L1_PT_SHIFT + PT_ORDER)
#define L3_PT_SHIFT (L2_PT_SHIFT + PT_ORDER)
#define L4_PT_SHIFT (L3_PT_SHIFT + PT_ORDER)

#define L1_PT_ENTRIES (PAGE_SIZE / PTE_SIZE)
#define L2_PT_ENTRIES (PAGE_SIZE / PTE_SIZE)
#if defined(__x86_64__)
#define L3_PT_ENTRIES (PAGE_SIZE / PTE_SIZE)
#define L4_PT_ENTRIES (PAGE_SIZE / PTE_SIZE)
#elif defined(__i386__)
#define L3_PT_ENTRIES 4
#endif

#define L1_MAP_SPACE (L1_PT_ENTRIES * PAGE_SIZE)
#define L2_MAP_SPACE (L2_PT_ENTRIES * L1_MAP_SPACE)
#define L3_MAP_SPACE (L3_PT_ENTRIES * L2_MAP_SPACE)
#define L4_MAP_SPACE (L4_PT_ENTRIES * L3_MAP_SPACE)

#define PADDR_SHIFT 52
#define PADDR_SIZE  (_U64(1) << PADDR_SHIFT)
#define PADDR_MASK  (~(PADDR_SIZE - 1))

#define VIRT_KERNEL_BASE _U64(0xffffffff80000000)
#define VIRT_KERNEL_MAP  _U64(0xffff800000000000)
#define VIRT_USER_BASE   _U64(0x0000000000400000)
#define VIRT_IDENT_BASE  _U64(0x0000000000000000)

#ifndef __ASSEMBLY__

enum pat_field {
    PA0 = 0,
    PA1,
    PA2,
    PA3,
    PA4,
    PA5,
    PA6,
    PA7,
};
typedef enum pat_field pat_field_t;

enum pat_memory_type {
    UC = 0, /* Uncacheable */
    WC = 1, /* Write Combining */
    WT = 4, /* Write Through */
    WP,     /* Write Protected */
    WB,     /* Write Back */
    UC_,    /* Uncached */
};
typedef enum pat_memory_type pat_memory_type_t;

/* clang-format off */
enum vmap_flags {
    VMAP_NONE               = 0x00000000,
    VMAP_IDENT              = 0x00000001,
    VMAP_KERNEL             = 0x00000002,
    VMAP_KERNEL_MAP         = 0x00000004,
    VMAP_KERNEL_USER        = 0x00000008,
    VMAP_KERNEL_USER_ACCESS = 0x00000010,
    VMAP_USER               = 0x00000020,
    VMAP_USER_IDENT         = 0x00000040,
    VMAP_USER_KERNEL        = 0x00000080,
    VMAP_USER_KERNEL_MAP    = 0x00000100,

    VMAP_ALL                = 0x000001ff,
};
/* clang-format on */
typedef enum vmap_flags vmap_flags_t;

typedef unsigned long paddr_t;
typedef unsigned long mfn_t;

#if defined(__x86_64__)
#define la57_enabled() 0 // TODO: 5 level paging unsupported for now
#define VA_BITS        (la57_enabled() ? 57 : 48) /* Number of canonical address bits */
#else
#define la57_enabled() 0
#define VA_BITS        32
#endif

#ifdef __i386__
#define PT_LEVELS 3 /* assumes PAE */
#else
#define PT_LEVELS (la57_enabled() ? 5 : 4)
#endif

#define _paddr(addr) ((paddr_t) _ul(addr))

#define PADDR_INVALID (~0x0UL)
#define MFN_INVALID   (paddr_to_mfn(PADDR_INVALID))

#define MAP_FAILED ((void *) 1)

#define IS_ADDR_SPACE_VA(va, as) (_ul(va) >= (as))
#define PADDR_TO_ORDER(addr)     (ctz(addr) - PAGE_SHIFT)

/* External declarations */

extern void pat_set_type(pat_field_t field, pat_memory_type_t type);
extern pat_memory_type_t pat_get_type(pat_field_t field);

/* Static declarations */

static inline bool virt_invalid(const void *va) {
    return !va || va == MAP_FAILED;
}

static inline paddr_t paddr_round_up(paddr_t pa) {
    return (pa + PAGE_SIZE - 1) & PAGE_MASK;
}

static inline void *virt_round_up(void *va) {
    return (void *) paddr_round_up(_paddr(va));
}

static inline bool has_vmap_flags(vmap_flags_t flags) {
    return (flags & VMAP_ALL) != VMAP_NONE;
}

static inline mfn_t paddr_to_mfn(paddr_t pa) {
    return (mfn_t)(pa >> PAGE_SHIFT);
}
static inline paddr_t mfn_to_paddr(mfn_t mfn) {
    return (paddr_t)(mfn << PAGE_SHIFT);
}

static inline void *_paddr_to_virt(paddr_t pa, unsigned long addr_space) {
    return _ptr(pa + addr_space);
}

static inline void *paddr_to_virt_kern(paddr_t pa) {
    return _paddr_to_virt(pa, VIRT_KERNEL_BASE);
}

static inline void *paddr_to_virt_map(paddr_t pa) {
    return _paddr_to_virt(pa, VIRT_KERNEL_MAP);
}

static inline void *paddr_to_virt_user(paddr_t pa) {
    return _paddr_to_virt(pa, VIRT_USER_BASE);
}

static inline void *paddr_to_virt(paddr_t pa) {
    return _paddr_to_virt(pa, VIRT_IDENT_BASE);
}

static inline void *mfn_to_virt_kern(mfn_t mfn) {
    return paddr_to_virt_kern(mfn << PAGE_SHIFT);
}

static inline void *mfn_to_virt_map(mfn_t mfn) {
    return paddr_to_virt_map(mfn << PAGE_SHIFT);
}

static inline void *mfn_to_virt_user(mfn_t mfn) {
    return paddr_to_virt_user(mfn << PAGE_SHIFT);
}

static inline void *mfn_to_virt(mfn_t mfn) {
    return paddr_to_virt(mfn << PAGE_SHIFT);
}

static inline paddr_t virt_to_paddr(const void *va) {
    paddr_t pa = (paddr_t) va;

    /* Order matters here */
    if (IS_ADDR_SPACE_VA(va, VIRT_KERNEL_BASE))
        return pa - VIRT_KERNEL_BASE;
    if (IS_ADDR_SPACE_VA(va, VIRT_KERNEL_MAP))
        return pa - VIRT_KERNEL_MAP;
    if (IS_ADDR_SPACE_VA(va, VIRT_USER_BASE))
        return pa - VIRT_USER_BASE;

    return pa - VIRT_IDENT_BASE;
}

static inline mfn_t virt_to_mfn(const void *va) {
    return paddr_to_mfn(virt_to_paddr(va));
}

static inline unsigned long order_to_flags(unsigned int order) {
    switch (order) {
    case PAGE_ORDER_2M:
        return L2_PROT;
    case PAGE_ORDER_1G:
        return L3_PROT;
    case PAGE_ORDER_4K:
    default:
        return L1_PROT;
    }
}

#endif /* __ASSEMBLY__ */

#endif /* KTF_PAGE_H */
