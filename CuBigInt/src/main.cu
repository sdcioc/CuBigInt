#include <CuBigInt/uint256.cuh>

int main() {
    printf("Hello, World!\n");
    uint256 a;
    // uint256_from_str(&a, "100000000000010");
    // uint256_from_hex(&a, "0000000000000000000000000000000000000000000000000000000fffffffff");

    uint256_from_hex(&a, "00000000000000000000000000000000000005");
    print_uint256(&a);
    uint256 b;
    // uint256_from_hex(&b, "000000000000000000000000000000000000000000000000000000f000000002");
    uint256_from_hex(&b, "00000000000000000000000000000000000002");
    print_uint256(&b);
    uint256 c;
    uint256_mul(&c, &a, &b);
    print_uint256(&c);
    printf("div result\n");
    uint256 d;
    uint256_div(&d, &c, &a);
    print_uint256(&d);

    uint256_from_hex(&a, "0000000000000000000005000000000");
    print_uint256(&a);

    // uint256_from_hex(&b, "000000000000000000000000000000000000000000000000000000f000000002");
    uint256_from_hex(&b, "0000000000000000000000000000002");
    print_uint256(&b);

    uint256_mul(&c, &a, &b);
    print_uint256(&c);


    uint256_div(&d, &c, &a);
    print_uint256(&d);

    // test bytes
    uint8_t bytes[32];
    uint256_to_bytes(bytes, &c, 32);
    for (int i = 0; i < 32; i++) {
        printf("%02x ", bytes[i]);
    }
    printf("\n");
    uint256_from_bytes(&a, bytes, 32);
    print_uint256(&a);

    //test bytes again
    uint256_to_bytes(bytes, &b, 32);
    for (int i = 0; i < 32; i++) {
        printf("%02x ", bytes[i]);
    }
    printf("\n");
    uint256_from_bytes(&a, bytes, 32);
    print_uint256(&a);

    return 0;
}