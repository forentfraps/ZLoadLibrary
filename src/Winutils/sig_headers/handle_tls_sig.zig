const __root = @This();
pub const __builtin = @import("std").zig.c_translation.builtins;
pub const __helpers = @import("std").zig.c_translation.helpers;

pub const int_least64_t = i64;
pub const uint_least64_t = u64;
pub const int_fast64_t = i64;
pub const uint_fast64_t = u64;
pub const int_least32_t = i32;
pub const uint_least32_t = u32;
pub const int_fast32_t = i32;
pub const uint_fast32_t = u32;
pub const int_least16_t = i16;
pub const uint_least16_t = u16;
pub const int_fast16_t = i16;
pub const uint_fast16_t = u16;
pub const int_least8_t = i8;
pub const uint_least8_t = u8;
pub const int_fast8_t = i8;
pub const uint_fast8_t = u8;
pub const intmax_t = c_longlong;
pub const uintmax_t = c_ulonglong;
pub const ptrdiff_t = c_longlong;
pub const wchar_t = c_ushort;
pub const max_align_t = extern struct {
    __aro_max_align_ll: c_longlong = 0,
    __aro_max_align_ld: c_longdouble = 0,
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t = extern struct {
    major: u32 = 0,
    minor: u32 = 0,
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group_t = extern struct {
    pattern: [*c]const u8 = null,
    mask: [*c]const u8 = null,
    length: u32 = 0,
    build_count: u32 = 0,
    versions: [*c]const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t = null,
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group0_pattern: [28]u8 = [28]u8{
    72,
    137,
    92,
    36,
    16,
    72,
    137,
    116,
    36,
    24,
    87,
    65,
    84,
    65,
    85,
    65,
    86,
    65,
    87,
    72,
    129,
    236,
    208,
    0,
    0,
    0,
    72,
    139,
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group0_mask: [4]u8 = [4]u8{
    255,
    255,
    255,
    15,
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group0_versions: [347]WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t = [347]WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 16384,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 16841,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17071,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17113,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17146,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17184,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17190,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17202,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17236,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17319,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17320,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17354,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17394,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17443,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17446,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17488,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17533,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17609,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17643,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17673,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17709,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17738,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17741,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17770,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17797,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17831,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17861,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17889,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17914,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17918,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17946,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 17976,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18005,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18036,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18063,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18064,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18094,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18132,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18135,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18158,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18186,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18187,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18215,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18218,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18244,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18275,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18305,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18308,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18333,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18334,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18335,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18368,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18395,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18427,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18453,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18485,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18486,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18519,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18545,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18575,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18608,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18609,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18638,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18666,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18696,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18725,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18756,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18782,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18818,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18842,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18874,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18875,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18906,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18932,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18967,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 18969,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19003,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19022,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19060,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19086,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19119,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19145,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19177,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19179,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19204,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19235,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19265,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19297,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19325,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19360,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19387,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19444,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19507,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19509,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19567,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19624,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19685,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19747,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19805,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19869,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19926,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19983,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 19986,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20048,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20107,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20162,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20232,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20308,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20345,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20402,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20469,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20526,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20596,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20651,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20680,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20710,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20747,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20751,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20761,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20766,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20793,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20796,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20826,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20857,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20883,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20890,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20915,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20947,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 20979,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 21014,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 21034,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 21073,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 21100,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 21128,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10240,
        .minor = 21161,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 0,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 306,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 494,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 545,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 589,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 633,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 672,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 679,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 713,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 753,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 839,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 842,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 873,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 916,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 962,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 965,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 1007,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 1045,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 1106,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 1176,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 1177,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 1232,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 1295,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 1356,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 1358,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 1417,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 1478,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 10586,
        .minor = 1540,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 0,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 82,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 103,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 105,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 187,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 206,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 222,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 321,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 351,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 447,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 479,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 571,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 693,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 726,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 729,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 953,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 969,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 970,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1066,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1198,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1230,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1358,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1378,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1480,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1532,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1537,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1593,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1613,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1670,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1715,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1737,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1794,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1797,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1884,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1914,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 1944,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2007,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2034,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2068,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2097,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2125,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2155,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2156,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2189,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2214,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2248,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2273,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2312,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2339,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2363,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2368,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2395,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2396,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2430,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2457,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2485,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2515,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2551,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2580,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2608,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2639,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2641,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2670,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2759,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2828,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2879,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2906,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2908,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2941,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2969,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2972,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 2999,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3025,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3053,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3056,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3085,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3115,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3144,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3181,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3204,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3206,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3241,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3242,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3243,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3274,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3300,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3326,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3384,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3443,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3474,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3503,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3504,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3542,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3564,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3595,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3630,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3659,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3686,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3750,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3755,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3808,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3866,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3930,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 3986,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4046,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4048,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4104,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4169,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4225,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4283,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4288,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4350,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4402,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4467,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4470,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4530,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4532,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4583,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4651,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4704,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4770,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4771,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4825,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4827,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4886,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4889,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 4946,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5006,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5066,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5125,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5127,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5192,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5246,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5291,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5356,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5427,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5429,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5501,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5502,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5582,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5648,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5717,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5786,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5850,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5921,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5980,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5989,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 5996,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 6085,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 6167,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 6252,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 6343,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 6351,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 6452,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 6529,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 6614,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 6709,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 6796,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 6799,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 6897,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 6981,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 7070,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 7159,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 7254,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 7259,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 7330,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 7336,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 7426,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 7428,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 7515,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 7606,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 7699,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 7785,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 7876,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 7969,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 7973,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 8066,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 8148,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 8246,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 8330,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 8422,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 8519,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 8594,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 14393,
        .minor = 8688,
    },
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group1_pattern: [20]u8 = [20]u8{
    72,
    137,
    92,
    36,
    16,
    72,
    137,
    116,
    36,
    24,
    72,
    137,
    124,
    36,
    32,
    65,
    85,
    65,
    86,
    65,
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group1_mask: [3]u8 = [3]u8{
    255,
    255,
    15,
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group1_versions: [378]WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t = [378]WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 0,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 447,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 483,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 502,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 540,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 608,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 632,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 675,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 726,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 729,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 877,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 936,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 994,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1058,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1112,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1155,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1182,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1209,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1235,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1266,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1292,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1324,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1358,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1387,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1418,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1446,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1478,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1506,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1508,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1563,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1596,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1631,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1659,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1689,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1716,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1746,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1784,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1785,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1805,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1808,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1839,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1868,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1897,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1898,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1928,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1955,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 1988,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2021,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2045,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2046,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2078,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2079,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2108,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2172,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2224,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2254,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2283,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2284,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2313,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2346,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2375,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2409,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2411,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2439,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2467,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2500,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2525,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2554,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2584,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2614,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2642,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 15063,
        .minor = 2679,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 15,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 64,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 98,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 125,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 192,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 194,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 214,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 248,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 251,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 309,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 334,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 371,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 402,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 431,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 461,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 492,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 522,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 547,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 551,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 579,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 611,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 637,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 665,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 666,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 699,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 726,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 755,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 785,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 820,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 846,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 847,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 904,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 936,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 967,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1004,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1029,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1059,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1087,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1127,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1146,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1150,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1182,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1217,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1237,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1239,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1268,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1296,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1331,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1365,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1387,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1392,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1420,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1421,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1451,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1481,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1508,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1565,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1625,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1654,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1685,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1686,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1717,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1747,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1775,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1776,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1806,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1868,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1932,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1937,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 1992,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 2045,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 2107,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 16299,
        .minor = 2166,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 113,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 116,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 145,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 175,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 207,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 239,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 267,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 295,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 329,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 356,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 357,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 387,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 388,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 418,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 449,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 476,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 535,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 592,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 628,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 657,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 693,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 719,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 720,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 752,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 753,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 778,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 815,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 836,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 900,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 904,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 959,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 997,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1016,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1049,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1082,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1110,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1139,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1171,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1198,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1199,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1237,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1256,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1316,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1350,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1411,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1500,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1533,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1621,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1645,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1679,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 1854,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18362,
        .minor = 2037,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1316,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1350,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1377,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1379,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1411,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1440,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1441,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1443,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1474,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1500,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1533,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1556,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1593,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1621,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1645,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1646,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1679,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1714,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1734,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1766,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1801,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1830,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1854,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1916,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 1977,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 2037,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 2039,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 2094,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 2158,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 2212,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 18363,
        .minor = 2274,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 120,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 258,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 282,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 318,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 348,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 376,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 434,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 438,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 469,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 493,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 527,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 556,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 593,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 613,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 652,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 653,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 675,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 708,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 739,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 778,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 795,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 832,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 856,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 918,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 978,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1042,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1098,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1100,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1165,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1219,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1281,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1335,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1455,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1516,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1574,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1641,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1696,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1761,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1817,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1880,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 1936,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2003,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2057,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2124,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2176,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2245,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2295,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2360,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2416,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2482,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2538,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2600,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2652,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2713,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2777,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2836,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2899,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 2960,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 3019,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 3079,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 3147,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 3197,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22000,
        .minor = 3260,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 317,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 525,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 608,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 674,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 675,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 755,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 819,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 900,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 963,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 1105,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 1194,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 1265,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 1344,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 1413,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 1485,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 1555,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 1635,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 1702,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 1778,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 1848,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 1928,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 1992,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 2070,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 2134,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 2215,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 2283,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 2361,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 2428,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 2506,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 2715,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 2792,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 2861,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 3007,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 3085,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 3155,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 3235,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 3296,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 3374,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 3447,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 3527,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 3593,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 3672,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 3733,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 3737,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 3810,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 3880,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 3958,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 4037,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 4111,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 4112,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 4169,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 4249,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 4317,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 4391,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 4460,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 4541,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 4602,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 4751,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 4830,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 4890,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 4974,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5039,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5124,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5126,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5189,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5192,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5262,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5335,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5413,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5415,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5472,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5549,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5624,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5699,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5768,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5771,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5840,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 5909,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 6060,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22621,
        .minor = 6345,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22631,
        .minor = 5840,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22631,
        .minor = 5984,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22631,
        .minor = 6133,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22631,
        .minor = 6199,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22631,
        .minor = 6276,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 22631,
        .minor = 6345,
    },
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group2_pattern: [24]u8 = [24]u8{
    72,
    137,
    92,
    36,
    16,
    72,
    137,
    116,
    36,
    24,
    87,
    65,
    84,
    65,
    85,
    65,
    86,
    65,
    87,
    72,
    129,
    236,
    0,
    1,
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group2_mask: [3]u8 = [3]u8{
    255,
    255,
    255,
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group2_versions: [233]WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t = [233]WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 112,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 137,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 165,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 167,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 191,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 228,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 254,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 285,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 286,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 320,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 345,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 376,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 407,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 441,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 471,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 472,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 523,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 556,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 590,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 619,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 648,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 677,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 706,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 753,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 765,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 766,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 799,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 829,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 858,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 860,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 885,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 915,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 950,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 984,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1006,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1009,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1039,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1040,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1069,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1099,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1130,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1184,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1246,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1276,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1304,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1345,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1365,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1399,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1401,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1425,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1456,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1488,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1550,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1553,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1610,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1667,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1726,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1792,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1845,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1902,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 1967,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 2026,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 2087,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 2088,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 2090,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 2145,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17134,
        .minor = 2208,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 168,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 194,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 195,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 253,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 292,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 316,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 348,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 379,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 402,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 404,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 437,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 439,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 475,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 503,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 504,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 529,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 557,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 592,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 593,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 615,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 652,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 678,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 719,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 720,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 737,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 740,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 774,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 775,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 802,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 805,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 831,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 832,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 864,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 914,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 973,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1007,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1012,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1039,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1075,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1098,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1131,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1132,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1158,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1192,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1217,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1282,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1294,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1339,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1369,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1397,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1432,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1457,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1490,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1518,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1554,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1577,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1579,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1613,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1637,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1697,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1728,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1757,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1790,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1817,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1821,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1823,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1852,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1879,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1911,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1935,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1971,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 1999,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2028,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2029,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2061,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2090,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2091,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2114,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2145,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2183,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2210,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2237,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2268,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2300,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2305,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2330,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2366,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2369,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2452,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2458,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2510,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2565,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2628,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2686,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2746,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2803,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2867,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2928,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2931,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 2989,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 3046,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 3113,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 3165,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 3232,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 3287,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 3346,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 3406,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 3469,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 3532,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 3534,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 3650,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 3653,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 3770,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 3772,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 3887,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 4010,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 4131,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 4252,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 4377,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 4492,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 4499,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 4644,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 4645,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 4720,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 4737,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 4851,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 4974,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 5122,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 5206,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 5329,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 5458,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 5576,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 5579,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 5696,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 5820,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 5830,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 5933,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 5936,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 6054,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 6189,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 6292,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 6293,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 6414,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 6532,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 6659,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 6775,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 6893,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 7009,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 7131,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 7136,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 7240,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 7249,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 7314,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 7322,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 7434,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 7553,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 7558,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 7678,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 7683,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 7792,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 7919,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 8024,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 8027,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 17763,
        .minor = 8146,
    },
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group3_pattern: [28]u8 = [28]u8{
    72,
    137,
    92,
    36,
    16,
    72,
    137,
    116,
    36,
    24,
    72,
    137,
    124,
    36,
    32,
    65,
    84,
    65,
    86,
    65,
    87,
    72,
    129,
    236,
    0,
    1,
    0,
    0,
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group3_mask: [4]u8 = [4]u8{
    255,
    255,
    255,
    15,
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group3_versions: [170]WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t = [170]WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 207,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 329,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 331,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 388,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 423,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 450,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 488,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 508,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 546,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 572,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 610,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 630,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 631,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 662,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 685,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 746,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 789,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 804,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 844,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 867,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 868,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 870,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 906,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 928,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 964,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 985,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1023,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1052,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1055,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1081,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1082,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1083,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1110,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1151,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1165,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1202,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1237,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1266,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1288,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1320,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1348,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1387,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1415,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1466,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1566,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1682,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1741,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1806,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 1949,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 2075,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 2130,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 2788,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 3031,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 3086,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 3155,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 3324,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 3393,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 3570,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 3636,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 3996,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 4239,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 4355,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 4522,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 4842,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 4957,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 5007,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 5438,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 5440,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 5794,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 6093,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 6456,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19041,
        .minor = 6691,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1466,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1469,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1503,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1526,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1566,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1586,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1620,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1645,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1682,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1706,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1708,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1741,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1766,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1806,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1826,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1865,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1889,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 1949,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2006,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2075,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2130,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2132,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2193,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2194,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2251,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2311,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2364,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2486,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2546,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2604,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2673,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2728,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2788,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2846,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19042,
        .minor = 2965,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 3086,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 3208,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 3324,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 3448,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 3570,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 3693,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 3803,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 3930,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 4046,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 4170,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 4291,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 4412,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 4529,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 4651,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 4780,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 4894,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 5011,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 5131,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 5247,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 5371,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 5487,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 5608,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 5737,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 5854,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 5856,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 5859,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 5965,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 6093,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 6216,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 6218,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 6332,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 6456,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19044,
        .minor = 6575,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 2913,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 3031,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 3155,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 3271,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 3393,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 3516,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 3636,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 3758,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 3996,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 4123,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 4239,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 4355,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 4474,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 4598,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 4717,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 4842,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 4957,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 5073,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 5198,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 5440,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 5555,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 5679,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 5796,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 5917,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 5968,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 6036,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 6159,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 6282,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 6396,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 19045,
        .minor = 6691,
    },
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group4_pattern: [24]u8 = [24]u8{
    76,
    139,
    220,
    73,
    137,
    91,
    16,
    73,
    137,
    115,
    24,
    87,
    65,
    84,
    65,
    85,
    65,
    86,
    65,
    87,
    72,
    129,
    236,
    0,
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group4_mask: [3]u8 = [3]u8{
    255,
    255,
    255,
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group4_versions: [48]WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t = [48]WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 1,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 863,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 1000,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 1150,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 1301,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 1457,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 1591,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 1742,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 1882,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 2033,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 2161,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 2314,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 2454,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 2605,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 2894,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 3037,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 3194,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 3323,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 3476,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 3624,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 3775,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 3912,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 3915,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 4061,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 4066,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 4202,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 4349,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 4351,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 4484,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 4652,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 4656,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 4768,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 4770,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 4946,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 5074,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 6584,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 6588,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 6725,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 6899,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 7019,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 7309,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26100,
        .minor = 7462,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26200,
        .minor = 6899,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26200,
        .minor = 6901,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26200,
        .minor = 7019,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26200,
        .minor = 7171,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26200,
        .minor = 7309,
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_version_t{
        .major = 26200,
        .minor = 7462,
    },
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_GROUPS: [5]WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group_t = [5]WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group_t{
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group_t{
        .pattern = @ptrCast(@alignCast(&WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group0_pattern)),
        .mask = @ptrCast(@alignCast(&WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group0_mask)),
        .length = @truncate(@sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group0_pattern)) / @sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group0_pattern[@as(c_int, 0)]))),
        .build_count = @truncate(@sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group0_versions)) / @sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group0_versions[@as(c_int, 0)]))),
        .versions = @ptrCast(@alignCast(&WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group0_versions)),
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group_t{
        .pattern = @ptrCast(@alignCast(&WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group1_pattern)),
        .mask = @ptrCast(@alignCast(&WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group1_mask)),
        .length = @truncate(@sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group1_pattern)) / @sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group1_pattern[@as(c_int, 0)]))),
        .build_count = @truncate(@sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group1_versions)) / @sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group1_versions[@as(c_int, 0)]))),
        .versions = @ptrCast(@alignCast(&WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group1_versions)),
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group_t{
        .pattern = @ptrCast(@alignCast(&WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group2_pattern)),
        .mask = @ptrCast(@alignCast(&WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group2_mask)),
        .length = @truncate(@sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group2_pattern)) / @sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group2_pattern[@as(c_int, 0)]))),
        .build_count = @truncate(@sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group2_versions)) / @sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group2_versions[@as(c_int, 0)]))),
        .versions = @ptrCast(@alignCast(&WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group2_versions)),
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group_t{
        .pattern = @ptrCast(@alignCast(&WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group3_pattern)),
        .mask = @ptrCast(@alignCast(&WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group3_mask)),
        .length = @truncate(@sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group3_pattern)) / @sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group3_pattern[@as(c_int, 0)]))),
        .build_count = @truncate(@sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group3_versions)) / @sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group3_versions[@as(c_int, 0)]))),
        .versions = @ptrCast(@alignCast(&WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group3_versions)),
    },
    WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group_t{
        .pattern = @ptrCast(@alignCast(&WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group4_pattern)),
        .mask = @ptrCast(@alignCast(&WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group4_mask)),
        .length = @truncate(@sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group4_pattern)) / @sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group4_pattern[@as(c_int, 0)]))),
        .build_count = @truncate(@sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group4_versions)) / @sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group4_versions[@as(c_int, 0)]))),
        .versions = @ptrCast(@alignCast(&WSIG_NTDLL_LDRPHANDLETLSDATA_X64_group4_versions)),
    },
};
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_GROUP_COUNT: usize = @sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_GROUPS)) / @sizeOf(@TypeOf(WSIG_NTDLL_LDRPHANDLETLSDATA_X64_GROUPS[@as(c_int, 0)]));

pub const __VERSION__ = "Aro aro-zig";
pub const __Aro__ = "";
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const __STDC_EMBED_NOT_FOUND__ = @as(c_int, 0);
pub const __STDC_EMBED_FOUND__ = @as(c_int, 1);
pub const __STDC_EMBED_EMPTY__ = @as(c_int, 2);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __GNUC__ = @as(c_int, 7);
pub const __GNUC_MINOR__ = @as(c_int, 1);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 0);
pub const __ARO_EMULATE_CLANG__ = @as(c_int, 1);
pub const __ARO_EMULATE_GCC__ = @as(c_int, 2);
pub const __ARO_EMULATE_MSVC__ = @as(c_int, 3);
pub const __ARO_EMULATE__ = __ARO_EMULATE_GCC__;
pub inline fn __building_module(x: anytype) @TypeOf(@as(c_int, 0)) {
    _ = &x;
    return @as(c_int, 0);
}
pub const _WIN32 = @as(c_int, 1);
pub const _WIN64 = @as(c_int, 1);
pub const WIN32 = @as(c_int, 1);
pub const __WIN32 = @as(c_int, 1);
pub const __WIN32__ = @as(c_int, 1);
pub const WINNT = @as(c_int, 1);
pub const __WINNT = @as(c_int, 1);
pub const __WINNT__ = @as(c_int, 1);
pub const WIN64 = @as(c_int, 1);
pub const __WIN64 = @as(c_int, 1);
pub const __WIN64__ = @as(c_int, 1);
pub const __MINGW64__ = @as(c_int, 1);
pub const __MSVCRT__ = @as(c_int, 1);
pub const __MINGW32__ = @as(c_int, 1);
pub const __declspec = @compileError("unable to translate C expr: unexpected token '__attribute__'"); // <builtin>:33:9
pub const _cdecl = @compileError("unable to translate macro: undefined identifier `__cdecl__`"); // <builtin>:34:9
pub const __cdecl = @compileError("unable to translate macro: undefined identifier `__cdecl__`"); // <builtin>:35:9
pub const _stdcall = @compileError("unable to translate macro: undefined identifier `__stdcall__`"); // <builtin>:36:9
pub const __stdcall = @compileError("unable to translate macro: undefined identifier `__stdcall__`"); // <builtin>:37:9
pub const _fastcall = @compileError("unable to translate macro: undefined identifier `__fastcall__`"); // <builtin>:38:9
pub const __fastcall = @compileError("unable to translate macro: undefined identifier `__fastcall__`"); // <builtin>:39:9
pub const _thiscall = @compileError("unable to translate macro: undefined identifier `__thiscall__`"); // <builtin>:40:9
pub const __thiscall = @compileError("unable to translate macro: undefined identifier `__thiscall__`"); // <builtin>:41:9
pub const unix = @as(c_int, 1);
pub const __unix = @as(c_int, 1);
pub const __unix__ = @as(c_int, 1);
pub const __code_model_small__ = @as(c_int, 1);
pub const __amd64__ = @as(c_int, 1);
pub const __amd64 = @as(c_int, 1);
pub const __x86_64__ = @as(c_int, 1);
pub const __x86_64 = @as(c_int, 1);
pub const __SEG_GS = @as(c_int, 1);
pub const __SEG_FS = @as(c_int, 1);
pub const __seg_gs = @compileError("unable to translate macro: undefined identifier `address_space`"); // <builtin>:52:9
pub const __seg_fs = @compileError("unable to translate macro: undefined identifier `address_space`"); // <builtin>:53:9
pub const __LAHF_SAHF__ = @as(c_int, 1);
pub const __AES__ = @as(c_int, 1);
pub const __PCLMUL__ = @as(c_int, 1);
pub const __LZCNT__ = @as(c_int, 1);
pub const __RDRND__ = @as(c_int, 1);
pub const __FSGSBASE__ = @as(c_int, 1);
pub const __BMI__ = @as(c_int, 1);
pub const __BMI2__ = @as(c_int, 1);
pub const __POPCNT__ = @as(c_int, 1);
pub const __PRFCHW__ = @as(c_int, 1);
pub const __RDSEED__ = @as(c_int, 1);
pub const __ADX__ = @as(c_int, 1);
pub const __MWAITX__ = @as(c_int, 1);
pub const __MOVBE__ = @as(c_int, 1);
pub const __SSE4A__ = @as(c_int, 1);
pub const __FMA__ = @as(c_int, 1);
pub const __F16C__ = @as(c_int, 1);
pub const __SHA__ = @as(c_int, 1);
pub const __FXSR__ = @as(c_int, 1);
pub const __XSAVE__ = @as(c_int, 1);
pub const __XSAVEOPT__ = @as(c_int, 1);
pub const __XSAVEC__ = @as(c_int, 1);
pub const __XSAVES__ = @as(c_int, 1);
pub const __CLFLUSHOPT__ = @as(c_int, 1);
pub const __CLWB__ = @as(c_int, 1);
pub const __WBNOINVD__ = @as(c_int, 1);
pub const __CLZERO__ = @as(c_int, 1);
pub const __RDPID__ = @as(c_int, 1);
pub const __RDPRU__ = @as(c_int, 1);
pub const __CRC32__ = @as(c_int, 1);
pub const __AVX2__ = @as(c_int, 1);
pub const __AVX__ = @as(c_int, 1);
pub const __SSE4_2__ = @as(c_int, 1);
pub const __SSE4_1__ = @as(c_int, 1);
pub const __SSSE3__ = @as(c_int, 1);
pub const __SSE3__ = @as(c_int, 1);
pub const __SSE2__ = @as(c_int, 1);
pub const __SSE__ = @as(c_int, 1);
pub const __SSE_MATH__ = @as(c_int, 1);
pub const __MMX__ = @as(c_int, 1);
pub const __GCC_HAVE_SYNC_COMPARE_AND_SWAP_8 = @as(c_int, 1);
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __ATOMIC_BOOL_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_SHORT_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_INT_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_LONG_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_LLONG_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_POINTER_LOCK_FREE = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 8);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SCHAR_WIDTH__ = @as(c_int, 8);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_MAX__ = @as(c_long, 2147483647);
pub const __LONG_WIDTH__ = @as(c_int, 32);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __LONG_LONG_WIDTH__ = @as(c_int, 64);
pub const __WCHAR_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 16);
pub const __INTMAX_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIG_ATOMIC_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __BITINT_MAXWIDTH__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 10);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 4);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 2);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTPTR_TYPE__ = c_longlong;
pub const __UINTPTR_TYPE__ = c_ulonglong;
pub const __INTMAX_TYPE__ = c_longlong;
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`"); // <builtin>:161:9
pub const __UINTMAX_TYPE__ = c_ulonglong;
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`"); // <builtin>:163:9
pub const __PTRDIFF_TYPE__ = c_longlong;
pub const __SIZE_TYPE__ = c_ulonglong;
pub const __WCHAR_TYPE__ = c_ushort;
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub const __INT64_TYPE__ = c_longlong;
pub const __INT64_FMTd__ = "lld";
pub const __INT64_FMTi__ = "lli";
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `LL`"); // <builtin>:184:9
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub const __UINT16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`"); // <builtin>:206:9
pub const __UINT32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulonglong;
pub const __UINT64_FMTo__ = "llo";
pub const __UINT64_FMTu__ = "llu";
pub const __UINT64_FMTx__ = "llx";
pub const __UINT64_FMTX__ = "llX";
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `ULL`"); // <builtin>:214:9
pub const __UINT64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const __INT64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_WIDTH__ = @as(c_int, 8);
pub const INT_LEAST8_FMTd__ = "hhd";
pub const INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const UINT_LEAST8_FMTo__ = "hho";
pub const UINT_LEAST8_FMTu__ = "hhu";
pub const UINT_LEAST8_FMTx__ = "hhx";
pub const UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_WIDTH__ = @as(c_int, 8);
pub const INT_FAST8_FMTd__ = "hhd";
pub const INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const UINT_FAST8_FMTo__ = "hho";
pub const UINT_FAST8_FMTu__ = "hhu";
pub const UINT_FAST8_FMTx__ = "hhx";
pub const UINT_FAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_WIDTH__ = @as(c_int, 16);
pub const INT_LEAST16_FMTd__ = "hd";
pub const INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_LEAST16_FMTo__ = "ho";
pub const UINT_LEAST16_FMTu__ = "hu";
pub const UINT_LEAST16_FMTx__ = "hx";
pub const UINT_LEAST16_FMTX__ = "hX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_WIDTH__ = @as(c_int, 16);
pub const INT_FAST16_FMTd__ = "hd";
pub const INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_FAST16_FMTo__ = "ho";
pub const UINT_FAST16_FMTu__ = "hu";
pub const UINT_FAST16_FMTx__ = "hx";
pub const UINT_FAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_WIDTH__ = @as(c_int, 32);
pub const INT_LEAST32_FMTd__ = "d";
pub const INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_LEAST32_FMTo__ = "o";
pub const UINT_LEAST32_FMTu__ = "u";
pub const UINT_LEAST32_FMTx__ = "x";
pub const UINT_LEAST32_FMTX__ = "X";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_WIDTH__ = @as(c_int, 32);
pub const INT_FAST32_FMTd__ = "d";
pub const INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_FAST32_FMTo__ = "o";
pub const UINT_FAST32_FMTu__ = "u";
pub const UINT_FAST32_FMTx__ = "x";
pub const UINT_FAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_longlong;
pub const __INT_LEAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const INT_LEAST64_FMTd__ = "lld";
pub const INT_LEAST64_FMTi__ = "lli";
pub const __UINT_LEAST64_TYPE__ = c_ulonglong;
pub const __UINT_LEAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const UINT_LEAST64_FMTo__ = "llo";
pub const UINT_LEAST64_FMTu__ = "llu";
pub const UINT_LEAST64_FMTx__ = "llx";
pub const UINT_LEAST64_FMTX__ = "llX";
pub const __INT_FAST64_TYPE__ = c_longlong;
pub const __INT_FAST64_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const INT_FAST64_FMTd__ = "lld";
pub const INT_FAST64_FMTi__ = "lli";
pub const __UINT_FAST64_TYPE__ = c_ulonglong;
pub const __UINT_FAST64_MAX__ = @as(c_ulonglong, 18446744073709551615);
pub const UINT_FAST64_FMTo__ = "llo";
pub const UINT_FAST64_FMTu__ = "llu";
pub const UINT_FAST64_FMTx__ = "llx";
pub const UINT_FAST64_FMTX__ = "llX";
pub const __FLT16_DENORM_MIN__ = @as(f16, 5.9604644775390625e-8);
pub const __FLT16_HAS_DENORM__ = "";
pub const __FLT16_DIG__ = @as(c_int, 3);
pub const __FLT16_DECIMAL_DIG__ = @as(c_int, 5);
pub const __FLT16_EPSILON__ = @as(f16, 9.765625e-4);
pub const __FLT16_HAS_INFINITY__ = "";
pub const __FLT16_HAS_QUIET_NAN__ = "";
pub const __FLT16_MANT_DIG__ = @as(c_int, 11);
pub const __FLT16_MAX_10_EXP__ = @as(c_int, 4);
pub const __FLT16_MAX_EXP__ = @as(c_int, 16);
pub const __FLT16_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_MIN_10_EXP__ = -@as(c_int, 4);
pub const __FLT16_MIN_EXP__ = -@as(c_int, 13);
pub const __FLT16_MIN__ = @as(f16, 6.103515625e-5);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_HAS_DENORM__ = "";
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = "";
pub const __FLT_HAS_QUIET_NAN__ = "";
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = @as(f64, 4.9406564584124654e-324);
pub const __DBL_HAS_DENORM__ = "";
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = @as(f64, 2.2204460492503131e-16);
pub const __DBL_HAS_INFINITY__ = "";
pub const __DBL_HAS_QUIET_NAN__ = "";
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = @as(f64, 2.2250738585072014e-308);
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 3.64519953188247460253e-4951);
pub const __LDBL_HAS_DENORM__ = "";
pub const __LDBL_DIG__ = @as(c_int, 18);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 21);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 1.08420217248550443401e-19);
pub const __LDBL_HAS_INFINITY__ = "";
pub const __LDBL_HAS_QUIET_NAN__ = "";
pub const __LDBL_MANT_DIG__ = @as(c_int, 64);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 4932);
pub const __LDBL_MAX_EXP__ = @as(c_int, 16384);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.18973149535723176502e+4932);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 4931);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 16381);
pub const __LDBL_MIN__ = @as(c_longdouble, 3.36210314311209350626e-4932);
pub const __FLT_EVAL_METHOD__ = @as(c_int, 0);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const __pic__ = @as(c_int, 2);
pub const __PIC__ = @as(c_int, 2);
pub inline fn __INT16_C(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub inline fn __INT32_C(x: anytype) @TypeOf(x) {
    _ = &x;
    return x;
}
pub const __INT64_C = __helpers.LL_SUFFIX;
pub const __UINT16_C = __helpers.U_SUFFIX;
pub const __UINT32_C = __helpers.U_SUFFIX;
pub const __UINT64_C = __helpers.ULL_SUFFIX;
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_H = "";
pub const __CLANG_STDINT_H = "";
pub const __int_least64_t = i64;
pub const __uint_least64_t = u64;
pub const __uint32_t_defined = "";
pub const __int_least32_t = i32;
pub const __uint_least32_t = u32;
pub const __int_least16_t = i16;
pub const __uint_least16_t = u16;
pub const __int_least8_t = i8;
pub const __uint_least8_t = u8;
pub const __int8_t_defined = "";
pub const __stdint_join3 = @compileError("unable to translate C expr: unexpected token '##'"); // C:\zig_compilers\zig\0.16.0-dev.2637+6a9510c0e\files\lib\include\stdint.h:291:9
pub const __intptr_t_defined = "";
pub const _INTPTR_T = "";
pub const _UINTPTR_T = "";
pub inline fn INT64_C(v: anytype) @TypeOf(__INT64_C(v)) {
    _ = &v;
    return __INT64_C(v);
}
pub inline fn UINT64_C(v: anytype) @TypeOf(__UINT64_C(v)) {
    _ = &v;
    return __UINT64_C(v);
}
pub inline fn INT32_C(v: anytype) @TypeOf(__INT32_C(v)) {
    _ = &v;
    return __INT32_C(v);
}
pub inline fn UINT32_C(v: anytype) @TypeOf(__UINT32_C(v)) {
    _ = &v;
    return __UINT32_C(v);
}
pub inline fn INT16_C(v: anytype) @TypeOf(__INT16_C(v)) {
    _ = &v;
    return __INT16_C(v);
}
pub inline fn UINT16_C(v: anytype) @TypeOf(__UINT16_C(v)) {
    _ = &v;
    return __UINT16_C(v);
}
pub const INT8_C = @compileError("unable to translate macro: undefined identifier `__INT8_C`"); // C:\zig_compilers\zig\0.16.0-dev.2637+6a9510c0e\files\lib\include\stdint.h:367:9
pub const UINT8_C = @compileError("unable to translate macro: undefined identifier `__UINT8_C`"); // C:\zig_compilers\zig\0.16.0-dev.2637+6a9510c0e\files\lib\include\stdint.h:368:9
pub const INT64_MAX = INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const INT64_MIN = -INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const UINT64_MAX = UINT64_C(__helpers.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const __INT_LEAST64_MIN = INT64_MIN;
pub const __INT_LEAST64_MAX = INT64_MAX;
pub const __UINT_LEAST64_MAX = UINT64_MAX;
pub const INT_LEAST64_MIN = __INT_LEAST64_MIN;
pub const INT_LEAST64_MAX = __INT_LEAST64_MAX;
pub const UINT_LEAST64_MAX = __UINT_LEAST64_MAX;
pub const INT_FAST64_MIN = __INT_LEAST64_MIN;
pub const INT_FAST64_MAX = __INT_LEAST64_MAX;
pub const UINT_FAST64_MAX = __UINT_LEAST64_MAX;
pub const INT32_MAX = INT32_C(__helpers.promoteIntLiteral(c_int, 2147483647, .decimal));
pub const INT32_MIN = -INT32_C(__helpers.promoteIntLiteral(c_int, 2147483647, .decimal)) - @as(c_int, 1);
pub const UINT32_MAX = UINT32_C(__helpers.promoteIntLiteral(c_int, 4294967295, .decimal));
pub const __INT_LEAST32_MIN = INT32_MIN;
pub const __INT_LEAST32_MAX = INT32_MAX;
pub const __UINT_LEAST32_MAX = UINT32_MAX;
pub const INT_LEAST32_MIN = __INT_LEAST32_MIN;
pub const INT_LEAST32_MAX = __INT_LEAST32_MAX;
pub const UINT_LEAST32_MAX = __UINT_LEAST32_MAX;
pub const INT_FAST32_MIN = __INT_LEAST32_MIN;
pub const INT_FAST32_MAX = __INT_LEAST32_MAX;
pub const UINT_FAST32_MAX = __UINT_LEAST32_MAX;
pub const INT16_MAX = INT16_C(@as(c_int, 32767));
pub const INT16_MIN = -INT16_C(@as(c_int, 32767)) - @as(c_int, 1);
pub const UINT16_MAX = UINT16_C(__helpers.promoteIntLiteral(c_int, 65535, .decimal));
pub const __INT_LEAST16_MIN = INT16_MIN;
pub const __INT_LEAST16_MAX = INT16_MAX;
pub const __UINT_LEAST16_MAX = UINT16_MAX;
pub const INT_LEAST16_MIN = __INT_LEAST16_MIN;
pub const INT_LEAST16_MAX = __INT_LEAST16_MAX;
pub const UINT_LEAST16_MAX = __UINT_LEAST16_MAX;
pub const INT_FAST16_MIN = __INT_LEAST16_MIN;
pub const INT_FAST16_MAX = __INT_LEAST16_MAX;
pub const UINT_FAST16_MAX = __UINT_LEAST16_MAX;
pub const INT8_MAX = INT8_C(@as(c_int, 127));
pub const INT8_MIN = -INT8_C(@as(c_int, 127)) - @as(c_int, 1);
pub const UINT8_MAX = UINT8_C(@as(c_int, 255));
pub const __INT_LEAST8_MIN = INT8_MIN;
pub const __INT_LEAST8_MAX = INT8_MAX;
pub const __UINT_LEAST8_MAX = UINT8_MAX;
pub const INT_LEAST8_MIN = __INT_LEAST8_MIN;
pub const INT_LEAST8_MAX = __INT_LEAST8_MAX;
pub const UINT_LEAST8_MAX = __UINT_LEAST8_MAX;
pub const INT_FAST8_MIN = __INT_LEAST8_MIN;
pub const INT_FAST8_MAX = __INT_LEAST8_MAX;
pub const UINT_FAST8_MAX = __UINT_LEAST8_MAX;
pub const __INTN_MIN = @compileError("unable to translate macro: undefined identifier `INT`"); // C:\zig_compilers\zig\0.16.0-dev.2637+6a9510c0e\files\lib\include\stdint.h:764:10
pub const __INTN_MAX = @compileError("unable to translate macro: undefined identifier `INT`"); // C:\zig_compilers\zig\0.16.0-dev.2637+6a9510c0e\files\lib\include\stdint.h:765:10
pub const __UINTN_MAX = @compileError("unable to translate macro: undefined identifier `UINT`"); // C:\zig_compilers\zig\0.16.0-dev.2637+6a9510c0e\files\lib\include\stdint.h:766:9
pub const __INTN_C = @compileError("unable to translate macro: undefined identifier `INT`"); // C:\zig_compilers\zig\0.16.0-dev.2637+6a9510c0e\files\lib\include\stdint.h:767:10
pub const __UINTN_C = @compileError("unable to translate macro: undefined identifier `UINT`"); // C:\zig_compilers\zig\0.16.0-dev.2637+6a9510c0e\files\lib\include\stdint.h:768:9
pub const INTPTR_MIN = -__INTPTR_MAX__ - @as(c_int, 1);
pub const INTPTR_MAX = __INTPTR_MAX__;
pub const UINTPTR_MAX = __UINTPTR_MAX__;
pub const PTRDIFF_MIN = -__PTRDIFF_MAX__ - @as(c_int, 1);
pub const PTRDIFF_MAX = __PTRDIFF_MAX__;
pub const SIZE_MAX = __SIZE_MAX__;
pub const INTMAX_MIN = -__INTMAX_MAX__ - @as(c_int, 1);
pub const INTMAX_MAX = __INTMAX_MAX__;
pub const UINTMAX_MAX = __UINTMAX_MAX__;
pub const SIG_ATOMIC_MIN = __INTN_MIN(__SIG_ATOMIC_WIDTH__);
pub const SIG_ATOMIC_MAX = __INTN_MAX(__SIG_ATOMIC_WIDTH__);
pub const WINT_MIN = @compileError("unable to translate macro: undefined identifier `__WINT_WIDTH__`"); // C:\zig_compilers\zig\0.16.0-dev.2637+6a9510c0e\files\lib\include\stdint.h:814:10
pub const WINT_MAX = @compileError("unable to translate macro: undefined identifier `__WINT_WIDTH__`"); // C:\zig_compilers\zig\0.16.0-dev.2637+6a9510c0e\files\lib\include\stdint.h:815:10
pub const WCHAR_MAX = __WCHAR_MAX__;
pub const WCHAR_MIN = __UINTN_C(__WCHAR_WIDTH__, @as(c_int, 0));
pub const INTMAX_C = @compileError("unable to translate macro: undefined identifier `__INTMAX_C`"); // C:\zig_compilers\zig\0.16.0-dev.2637+6a9510c0e\files\lib\include\stdint.h:830:10
pub const UINTMAX_C = @compileError("unable to translate macro: undefined identifier `__UINTMAX_C`"); // C:\zig_compilers\zig\0.16.0-dev.2637+6a9510c0e\files\lib\include\stdint.h:831:9
pub const __STDC_VERSION_STDDEF_H__ = @as(c_long, 202311);
pub const NULL = __helpers.cast(?*anyopaque, @as(c_int, 0));
pub const offsetof = @compileError("unable to translate macro: undefined identifier `__builtin_offsetof`"); // C:\zig_compilers\zig\0.16.0-dev.2637+6a9510c0e\files\lib\compiler\aro\include\stddef.h:18:9
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_DLL_NAME = "ntdll";
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_FUNCTION_NAME = "LdrpHandleTlsData";
pub const WSIG_NTDLL_LDRPHANDLETLSDATA_X64_ARCH = "x64";
