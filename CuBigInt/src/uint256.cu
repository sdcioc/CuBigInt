#include <CuBigInt/uint256.cuh>

__host__ __device__ int uint256_cmp(const uint256 *a, const uint256 *b) {
    for (int i = UINT256_WORDS - 1; i >= 0; i--) {
        if (a->words[i] < b->words[i]) return -1;
        if (a->words[i] > b->words[i]) return 1;
    }
    return 0;
}

__host__ __device__ int uint256_cmp_word(const uint256 *a, bigint_word b) {
    for (int i = UINT256_WORDS - 1; i >= 0; i--) {
        if (i != 0 && a->words[i] != 0) return 1;
        if (a->words[i] < b) return -1;
    }
    return 0;
}

__host__ __device__ int uint256_is_zero(const uint256 *a) {
    for (int i = 0; i < UINT256_WORDS; i++) {
        if (a->words[i] != 0) return 0;
    }
    return 1;
}

__host__ __device__ int uint256_set_zero(uint256 *a) {
    memset(a->words, 0, sizeof(a->words));
    return 0;
}

__host__ __device__ uint32_t uint256_get_uint32_t(const uint256 *a) { return a->words[0]; }

__host__ __device__ uint64_t uint256_get_uint64_t(const uint256 *a) {
    return (uint64_t)a->words[1] << 32 | a->words[0];
}

__host__ __device__ uint256 *uint256_cpy(uint256 *dst, const uint256 *src) {
    memcpy(dst->words, src->words, sizeof(dst->words));
    return dst;
}

__host__ __device__ int uint256_bit_length(const uint256 *num) {
    // printf("bit length\n");
    for (int i = UINT256_WORDS - 1; i >= 0; --i) {
        uint32_t word = num->words[i];
        // printf("word %d: %08x\n", i, word);
        if (word != 0) {
            // Found the first non-zero word
            int bits = 32 * (i);
            // printf("bits: %d\n", bits);
            // Now find the highest bit set in word
            for (int j = 31; j >= 0; --j) {
                if (word & (1U << j)) {
                    return bits + j + 1;
                }
            }
        }
    }
    return 0;
}

__host__ __device__ void uint256_set_bit(uint256 *num, int bit_index, uint8_t value) {
    int word_index = bit_index / 32;
    int bit_in_word = (bit_index % 32);  // Big-endian bit indexing
    if (value) {
        num->words[word_index] |= (1U << bit_in_word);
    } else {
        num->words[word_index] &= ~(1U << bit_in_word);
    }
}
// __host__ __device__ uint256* uint256_clr_bit(uint256 *dst, unsigned bit_index) {
//     dst->words[bit_index / 32] &= ~(1 << (bit_index % 32));
//     return dst;
// }

// __host__ __device__ uint256* uint256_set_bit(uint256 *dst, unsigned bit_index) {
//     dst->words[bit_index / 32] |= (1 << (bit_index % 32));
//     return dst;
// }

// TODO: check if this is correct
__host__ __device__ uint256 *uint256_mul(uint256 *dst, const uint256 *a, const uint256 *b) {
    memset(dst->words, 0, sizeof(dst->words));  // Initialize dst to zero
    for (int i = 0; i < UINT256_WORDS; i++) {
        for (int j = 0; j < UINT256_WORDS; j++) {
            if (i + j < UINT256_WORDS) {
                bigint_word lo = bigint_word_mul_lo(a->words[i], b->words[j]);
                bigint_word hi = bigint_word_mul_hi(a->words[i], b->words[j]);
                dst->words[i + j] += lo;
                if (i + j + 1 < UINT256_WORDS) {
                    dst->words[i + j + 1] += hi;
                }
            }
        }
    }
    return dst;
}

__host__ __device__ uint256 *uint256_from_hex(uint256 *dst, const char *src) {
    size_t len = strlen(src);
    memset(dst->words, 0, sizeof(dst->words));

    // Check for "0x" or "0X" prefix and adjust the starting point
    size_t start = 0;
    if (len > 1 && src[0] == '0' && (src[1] == 'x' || src[1] == 'X')) {
        start = 2;
        len -= 2;
    }

    // Process each character from the start to the end for big-endian
    for (size_t i = 0; i < len; i++) {
        char c = src[len - 1 - i + start];
        bigint_word value;
        if (c >= '0' && c <= '9') {
            value = c - '0';
        } else if (c >= 'a' && c <= 'f') {
            value = 10 + (c - 'a');
        } else if (c >= 'A' && c <= 'F') {
            value = 10 + (c - 'A');
        } else {
            continue;  // skip invalid characters
        }
        size_t word_index = (i / (2 * sizeof(bigint_word)));
        size_t bit_position = (4 * (i % (2 * sizeof(bigint_word))));
        dst->words[word_index] |= value << bit_position;
    }
    return dst;
}

__host__ __device__ void print_uint256(const uint256 *a) {
    for (int i = 0; i < UINT256_WORDS; i++) {
        printf("%08x ", a->words[UINT256_WORDS - 1 - i]);
    }
    printf("\n");
}

__host__ __device__ void print_bigint(const bigint *a) {
    for (int i = 0; i < a->size; i++) {
        printf("%08x ", a->words[a->size - 1 - i]);
    }
    printf("\n");
}

__host__ __device__ uint256 *uint256_from_uint32(uint256 *dst, uint32_t src) {
    memset(dst->words, 0, sizeof(dst->words));
    dst->words[0] = src;
    return dst;
}

__host__ __device__ uint256 *uint256_from_word(uint256 *dst, bigint_word a) {
    memset(dst->words, 0, sizeof(dst->words));
    dst->words[0] = a;
    return dst;
}

__host__ __device__ uint256 *uint256_add(uint256 *dst, const uint256 *a, const uint256 *b) {
    bigint_word carry = 0;
    for (int i = 0; i < UINT256_WORDS; i++) {
        bigint_word sum = a->words[i] + b->words[i] + carry;
        carry = (sum < a->words[i]) ? 1 : 0;
        dst->words[i] = sum;
    }
    return dst;
}

__host__ __device__ uint256 *uint256_sub(uint256 *dst, const uint256 *a, const uint256 *b) {
    bigint_word borrow = 0;
    for (int i = 0; i < UINT256_WORDS; i++) {
        bigint_word diff = a->words[i] - b->words[i] - borrow;
        borrow = (a->words[i] < b->words[i] + borrow) ? 1 : 0;
        dst->words[i] = diff;
    }
    return dst;
}

// __host__ __device__ uint256* uint256_mul(uint256 *dst, const uint256 *a, const uint256 *b) {
//     uint256 tmp;
//     memset(dst->words, 0, sizeof(dst->words));
//     for (int i = 0; i < UINT256_WORDS; i++) {
//         if (a->words[i] == 0) continue;
//         memset(tmp.words, 0, sizeof(tmp.words));
//         bigint_word carry = 0;
//         for (int j = 0; j < UINT256_WORDS - i; j++) {
//             bigint_word product = a->words[i] * b->words[j] + carry;
//             carry = product >> BIGINT_WORD_BITS;
//             tmp.words[i + j] = product;
//         }
//         uint256_add(dst, dst, &tmp);
//     }
//     return dst;
// }

/*
__host__ __device__ uint256* uint256_div_mod(uint256 *dst_quotient, uint256 *dst_remainder,
                                             const uint256 *src_numerator, const uint256 *src_denominator) {
    uint256 quotient;
    memset(quotient.words, 0, sizeof(quotient.words));
    uint256 remainder;
    uint256 denominator;
    uint256_cpy(&remainder, src_numerator);
    uint256_cpy(&denominator, src_denominator);

    // Check for division by zero
    if (uint256_is_zero(&denominator)) {
        memset(dst_quotient->words, 0, sizeof(dst_quotient->words));
        memset(dst_remainder->words, 0, sizeof(dst_remainder->words));
        return NULL;
    }

    // If numerator < denominator, quotient is 0, remainder is numerator
    if (uint256_cmp(&remainder, &denominator) < 0) {
        *dst_quotient = quotient;
        *dst_remainder = remainder;
        return dst_quotient;
    }
    printf("start division\n");
    printf("remainder: ");
    print_uint256(&remainder);
    printf("quotient: ");
    print_uint256(&quotient);
    printf("\n-----------------------\n");
    // Main division loop using repeated subtraction
    while (uint256_cmp(&remainder, &denominator) >= 0) {
        printf("remainder: ");
        print_uint256(&remainder);
        printf("denominator: ");
        print_uint256(&denominator);
        uint256_sub(&remainder, &remainder, &denominator);
        uint256_add_word(&quotient, &quotient, 1);
        printf("quotient: ");
        print_uint256(&quotient);
        printf("remainder: ");
        print_uint256(&remainder);
        printf("\n------------------\n");
    }

    *dst_quotient = quotient;
    *dst_remainder = remainder;
    return dst_quotient;
}
*/
__host__ __device__ uint256 *uint256_div_mod(uint256 *dst_quotient, uint256 *dst_remainder,
                                             const uint256 *src_numerator, const uint256 *src_denominator) {
    uint256 quotient;
    memset(quotient.words, 0, sizeof(quotient.words));
    uint256 numerator;
    uint256 denominator;
    uint256_cpy(&numerator, src_numerator);
    uint256_cpy(&denominator, src_denominator);

    // Check for division by zero
    if (uint256_is_zero(&denominator)) {
        memset(dst_quotient->words, 0, sizeof(dst_quotient->words));
        memset(dst_remainder->words, 0, sizeof(dst_remainder->words));
        return NULL;  // Division by zero
    }

    // If numerator < denominator, quotient is 0, remainder is numerator
    if (uint256_cmp(&numerator, &denominator) < 0) {
        *dst_quotient = quotient;    // Quotient is zero
        *dst_remainder = numerator;  // Remainder is the numerator
        return dst_quotient;
    }

    // Determine the shift required to align the numerator and denominator
    int nbits_numerator = uint256_bit_length(&numerator);

    int nbits_denominator = uint256_bit_length(&denominator);

    int shift = nbits_numerator - nbits_denominator;
    // return NULL;
    uint256 shifted_denominator;
    memset(shifted_denominator.words, 0, sizeof(shifted_denominator.words));

    uint256_shift_left(&shifted_denominator, &denominator, shift);

    for (; shift >= 0; shift--) {
        if (uint256_cmp(&numerator, &shifted_denominator) >= 0) {
            uint256_sub(&numerator, &numerator, &shifted_denominator);
            uint256_set_bit(&quotient, shift, 1);
        }
        uint256_shift_right(&shifted_denominator, &shifted_denominator, 1);
    }

    uint256_cpy(dst_quotient, &quotient);
    uint256_cpy(dst_remainder, &numerator);
    return dst_quotient;
}

__host__ __device__ bigint *bigint_from_uint256(bigint *dst, const uint256 *src) {
    bigint_init(dst);
    bigint_reserve(dst, UINT256_WORDS);
    dst->size = UINT256_WORDS;
    memcpy(dst->words, src->words, sizeof(dst->words));
    return dst;
}

__host__ __device__ uint256 *uint256_from_bigint(uint256 *dst, const bigint *src) {
    memcpy(dst->words, src->words, sizeof(dst->words));
    return dst;
}

__host__ __device__ uint256 *uint256_div(uint256 *dst, const uint256 *numerator, const uint256 *denominator) {
    uint256 remainder;
    return uint256_div_mod(dst, &remainder, numerator, denominator);
}

__host__ __device__ uint256 *uint256_mod(uint256 *dst, const uint256 *numerator, const uint256 *denominator) {
    uint256 quotient;
    return uint256_div_mod(&quotient, dst, numerator, denominator);
}
/*
__host__ __device__ uint256* uint256_shift_left(uint256 *dst, const uint256 *src, unsigned shift) {
    if (shift >= UINT256_WORDS * BIGINT_WORD_BITS) {
        memset(dst->words, 0, sizeof(dst->words));
        return dst;
    }

    unsigned word_shift = shift / BIGINT_WORD_BITS;
    unsigned bit_shift = shift % BIGINT_WORD_BITS;
    unsigned inv_bit_shift = BIGINT_WORD_BITS - bit_shift;

    for (int i = UINT256_WORDS - 1; i >= 0; i--) {
        if (i >= word_shift) {
            dst->words[i] = src->words[i - word_shift] << bit_shift;
            if (i > word_shift && bit_shift != 0) {
                dst->words[i] |= src->words[i - word_shift - 1] >> inv_bit_shift;
            }
        } else {
            dst->words[i] = 0;
        }
    }
    return dst;
}

__host__ __device__ uint256* uint256_shift_right(uint256 *dst, const uint256 *src, unsigned shift) {
    if (shift >= UINT256_WORDS * BIGINT_WORD_BITS) {
        memset(dst->words, 0, sizeof(dst->words));
        return dst;
    }

    unsigned word_shift = shift / BIGINT_WORD_BITS;
    unsigned bit_shift = shift % BIGINT_WORD_BITS;
    unsigned inv_bit_shift = BIGINT_WORD_BITS - bit_shift;

    for (int i = 0; i < UINT256_WORDS; i++) {
        if (i + word_shift < UINT256_WORDS) {
            dst->words[i] = src->words[i + word_shift] >> bit_shift;
            if (i + word_shift + 1 < UINT256_WORDS && bit_shift != 0) {
                dst->words[i] |= src->words[i + word_shift + 1] << inv_bit_shift;
            }
        } else {
            dst->words[i] = 0;
        }
    }
    return dst;
}
*/
__host__ __device__ uint256 *uint256_shift_left(uint256 *dst, const uint256 *src, uint32_t shift) {
    if (shift <= 0) return dst;
    if (dst != src) uint256_cpy(dst, src);
    while (shift >= 32) {
        for (int i = UINT256_WORDS - 1; i > 0; --i) dst->words[i] = dst->words[i - 1];
        dst->words[0] = 0;
        shift -= 32;
    }
    if (shift > 0) {
        uint32_t carry = 0;
        for (int i = 0; i < UINT256_WORDS; ++i) {
            uint32_t word = dst->words[i];
            dst->words[i] = (word << shift) | carry;
            carry = word >> (32 - shift);
        }
    }
    return dst;
}

__host__ __device__ uint256 *uint256_shift_right(uint256 *dst, const uint256 *src, uint32_t shift) {
    if (shift <= 0) return dst;
    while (shift >= 32) {
        for (int i = UINT256_WORDS - 1; i > 0; --i) {
            dst->words[i] = src->words[i - 1];
        }
        dst->words[0] = 0;
        shift -= 32;
    }
    if (shift > 0) {
        uint32_t carry = 0;
        for (int i = UINT256_WORDS - 1; i >= 0; --i) {
            uint32_t word = src->words[i];
            dst->words[i] = (word >> shift) | carry;
            carry = word << (32 - shift);
        }
    }
    return dst;
}

__host__ __device__ uint256 *uint256_bitwise_and(uint256 *dst, const uint256 *a, const uint256 *b) {
    for (int i = 0; i < UINT256_WORDS; i++) {
        dst->words[i] = a->words[i] & b->words[i];
    }
    return dst;
}

__host__ __device__ uint256 *uint256_bitwise_or(uint256 *dst, const uint256 *a, const uint256 *b) {
    for (int i = 0; i < UINT256_WORDS; i++) {
        dst->words[i] = a->words[i] | b->words[i];
    }
    return dst;
}

__host__ __device__ uint256 *uint256_bitwise_xor(uint256 *dst, const uint256 *a, const uint256 *b) {
    for (int i = 0; i < UINT256_WORDS; i++) {
        dst->words[i] = a->words[i] ^ b->words[i];
    }
    return dst;
}

__host__ __device__ uint256 *uint256_bitwise_not(uint256 *dst, const uint256 *a) {
    for (int i = 0; i < UINT256_WORDS; i++) {
        dst->words[i] = ~a->words[i];
    }
    return dst;
}

__host__ __device__ uint8_t *uint256_to_bytes(uint8_t *dst, const uint256 *src, size_t len) {
    size_t total_bytes = sizeof(src->words);
    for (size_t i = 0; i < len && i < total_bytes; i++) {
        size_t word_index = (total_bytes - 1 - i) / sizeof(bigint_word);
        size_t byte_position = i % sizeof(bigint_word);
        dst[i] = (src->words[word_index] >> (8 * (sizeof(bigint_word) - 1 - byte_position))) & 0xFF;
    }
    return dst;
}

__host__ __device__ uint256 *uint256_from_bytes(uint256 *dst, const uint8_t *src, size_t len) {
    // Initialize the words array to zero
    memset(dst->words, 0, sizeof(dst->words));
    size_t offset = sizeof(dst->words) - len;
    // Convert the byte array to the uint256 structure
    size_t total_bytes = sizeof(dst->words);
    for (size_t i = 0; i < len && i < total_bytes; i++) {
        size_t word_index = UINT256_WORDS - 1 - (i + offset) / sizeof(bigint_word);
        size_t byte_position = (i + offset) % sizeof(bigint_word);
        dst->words[word_index] |= ((bigint_word)src[i]) << (8 * (sizeof(bigint_word) - 1 - byte_position));
    }

    return dst;
}

// __host__ __device__ uint256* uint256_add_word(uint256 *dst, const uint256 *src_a, bigint_word b);
__host__ __device__ uint256 *uint256_add_word(uint256 *dst, const uint256 *src_a, bigint_word b) {
    uint256 tmp;
    uint256_from_word(&tmp, b);
    return uint256_add(dst, src_a, &tmp);
}

// __host__ __device__ uint256* uint256_sub_word(uint256 *dst, const uint256 *src_a, bigint_word b);
__host__ __device__ uint256 *uint256_sub_word(uint256 *dst, const uint256 *src_a, bigint_word b) {
    uint256 tmp;
    uint256_from_word(&tmp, b);
    return uint256_sub(dst, src_a, &tmp);
}

// __host__ __device__ char* uint256_write_base(
//     char *dst,
//     int *n_dst,
//     const uint256 *a,
//     bigint_word base,
//     int zero_terminate
// );
__host__ __device__ char *uint256_to_hex(char *dst, const uint256 *a) {
    int n = 0;
    static const char *table = "0123456789abcdef";

    for (int i = UINT256_WORDS - 1; i >= 0; i--) {
        for (int j = sizeof(bigint_word) * 2 - 1; j >= 0; j--) {
            bigint_word byte = (a->words[i] >> (j * 4)) & 0xF;
            dst[n++] = table[byte];
        }
    }

    dst[n] = '\0';
    return dst;
}
