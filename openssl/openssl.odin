package openssl

import "core:c"
import "core:c/libc"

//SHARED :: #config(OPENSSL_SHARED, false) //edited

when ODIN_ARCH == .amd64 {
    __ARCH_end :: "_amd64"
} else when ODIN_ARCH == .i386 {
    __ARCH_end :: "_i386"
} else when ODIN_ARCH == .arm64 {
    __ARCH_end :: "_arm64"
} else when ODIN_ARCH == .riscv64 {
    __ARCH_end :: "_riscv64"
} else when ODIN_ARCH == .arm32 {
    __ARCH_end :: "_arm32"
} else when ODIN_OS == .JS || ODIN_OS == .WASI {
    __ARCH_end :: "_wasm"
}

when ODIN_OS == .Windows && ODIN_PLATFORM_SUBTARGET == .Default {
	ARCH_end :: __ARCH_end + ".lib"
	ARCH_end_so :: __ARCH_end + ".dll"
} else {
	ARCH_end :: __ARCH_end + ".a"
	ARCH_end_so :: __ARCH_end + ".so"
}

when ODIN_PLATFORM_SUBTARGET == .Android {
	foreign import lib {
		"lib/android/libssl" + ARCH_end,
		"lib/android/libcrypto" + ARCH_end,
	}
} else when ODIN_OS == .Windows {
	foreign import lib {
		"lib/windows/libssl" + ARCH_end,
		"lib/windows/libcrypto" + ARCH_end,
		"system:ws2_32.lib",
		"system:gdi32.lib",
		"system:advapi32.lib",
		"system:crypt32.lib",
		"system:user32.lib",
	}
} else when ODIN_OS == .Darwin {
	foreign import lib {
		"system:ssl.3",
		"system:crypto.3",
	}
} else {
	foreign import lib {//linux have ssl lib.a but use system default.
		"system:ssl",
		"system:crypto",
	}
}

Version :: bit_field u32 {
	pre_release: uint | 4,
	patch:       uint | 16,
	minor:       uint | 8,
	major:       uint | 4,
}

VERSION: Version

@(private, init)
version_check :: proc "contextless" () {
	VERSION = Version(OpenSSL_version_num())
	assert_contextless(VERSION.major == 3, "invalid OpenSSL library version, expected 3.x")
}

SSL_METHOD :: struct {}
SSL_CTX :: struct {}
SSL :: struct {}

SSL_CTRL_SET_TLSEXT_HOSTNAME :: 55

TLSEXT_NAMETYPE_host_name :: 0

foreign lib {
	TLS_client_method :: proc() -> ^SSL_METHOD ---
	SSL_CTX_new :: proc(method: ^SSL_METHOD) -> ^SSL_CTX ---
	SSL_new :: proc(ctx: ^SSL_CTX) -> ^SSL ---
	SSL_set_fd :: proc(ssl: ^SSL, fd: c.int) -> c.int ---
	SSL_connect :: proc(ssl: ^SSL) -> c.int ---
	SSL_get_error :: proc(ssl: ^SSL, ret: c.int) -> c.int ---
	SSL_read :: proc(ssl: ^SSL, buf: [^]byte, num: c.int) -> c.int ---
	SSL_write :: proc(ssl: ^SSL, buf: [^]byte, num: c.int) -> c.int ---
	SSL_free :: proc(ssl: ^SSL) ---
	SSL_CTX_free :: proc(ctx: ^SSL_CTX) ---
	ERR_print_errors_fp :: proc(fp: ^libc.FILE) ---
	SSL_ctrl :: proc(ssl: ^SSL, cmd: c.int, larg: c.long, parg: rawptr) -> c.long ---
    OpenSSL_version_num :: proc() -> c.ulong ---
}

// This is a macro in c land.
SSL_set_tlsext_host_name :: proc(ssl: ^SSL, name: cstring) -> c.int {
	return c.int(SSL_ctrl(ssl, SSL_CTRL_SET_TLSEXT_HOSTNAME, TLSEXT_NAMETYPE_host_name, rawptr(name)))
}

ERR_print_errors :: proc {
	ERR_print_errors_fp,
	ERR_print_errors_stderr,
}

ERR_print_errors_stderr :: proc() {
	ERR_print_errors_fp(libc.stderr)
}
