/* SPDX-License-Identifier: BSD-2-Clause
 * A35 / A356EXXS4AYB2: consume the saved recovery boot selection in TWRP.
 * This does not reboot, flash firmware, or alter the current recovery session.
 * sboot's save_env_file/get_env code places integer slot 0 (REBOOT_MODE)
 * at PARAM+0x700200. Its header is 0xcafe0003, version 0x100. Mode 4 is
 * recovery; mode 0 is normal. TWRP shutdown does not reset this saved mode.
 * Preserve every other mode, including FOTA, and every other parameter.
 */
#define _GNU_SOURCE
#include <fcntl.h>
#include <linux/fs.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <unistd.h>

#define PARAM_SIZE (8ULL * 1024 * 1024)
#define ENV_BASE 0x700000
#define SELECTOR (ENV_BASE + 0x200)

static uint32_t le32(const unsigned char *p)
{
    return (uint32_t)p[0] | (uint32_t)p[1] << 8 |
           (uint32_t)p[2] << 16 | (uint32_t)p[3] << 24;
}

/* Each descriptor belongs only to this process, so seek + I/O is sufficient.
 * These wrappers also work with Linux's small nolibc runtime. */
static ssize_t read_at(int fd, void *buf, size_t count, off_t offset)
{
    return lseek(fd, offset, SEEK_SET) == offset ? read(fd, buf, count) : -1;
}

static ssize_t write_at(int fd, const void *buf, size_t count, off_t offset)
{
    return lseek(fd, offset, SEEK_SET) == offset ? write(fd, buf, count) : -1;
}

static void report(const char *s)
{
    puts(s);
#ifndef A35_TEST
    int fd = open("/tmp/a35-boot-selection.log", O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC, 0600);
    if (fd >= 0) {
        (void)write(fd, s, strlen(s));
        (void)write(fd, "\n", 1);
        close(fd);
    }
#endif
}

int main(int argc, char **argv)
{
    const char *path = "/dev/block/by-name/param";
    int check = argc == 2 && strcmp(argv[1], "--check") == 0;
#ifdef A35_TEST
    if (argc < 2 || argc > 3) return 2;
    path = argv[1];
    check = argc == 3 && strcmp(argv[2], "--check") == 0;
#else
    if (argc != 1 && !check) return 2;
#endif
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    struct stat st;
    uint64_t size = 0;
    unsigned char before[0x400], after[sizeof(before)];
    if (fd < 0 || fstat(fd, &st)) goto fail;
    if (S_ISBLK(st.st_mode)) {
        if (ioctl(fd, BLKGETSIZE64, &size)) goto fail;
    }
#ifdef A35_TEST
    else if (S_ISREG(st.st_mode)) size = st.st_size;
#endif
    else goto fail;
    if (size != PARAM_SIZE || read_at(fd, before, sizeof(before), ENV_BASE) != sizeof(before)) goto fail;
    if (le32(before) != 0xcafe0003 || le32(before + 4) != 0x100) {
        report("A35: unrecognized PARAM layout; left unchanged.");
        close(fd);
        return 1;
    }
    uint32_t mode = le32(before + 0x200);
    char message[100];
    snprintf(message, sizeof(message), "A35: saved REBOOT_MODE=%u (%s).", mode,
             mode == 4 ? "recovery" : mode == 0 ? "normal" : "other; preserving");
    report(message);
    close(fd);
    fd = -1;
    if (check || mode != 4) return 0;

    fd = open(path, O_RDWR | O_SYNC | O_CLOEXEC);
    if (fd < 0 || read_at(fd, after, sizeof(after), ENV_BASE) != sizeof(after)) goto fail;
    if (memcmp(before, after, sizeof(before))) {
        report("A35: PARAM changed during inspection; left unchanged.");
        close(fd);
        return 1;
    }
    const unsigned char normal[4] = {0};
    if (write_at(fd, normal, sizeof(normal), SELECTOR) != sizeof(normal) || fsync(fd)) goto fail;
    memset(before + 0x200, 0, sizeof(normal));
    if (read_at(fd, after, sizeof(after), ENV_BASE) != sizeof(after) || memcmp(before, after, sizeof(before))) goto fail;
    close(fd);
    report("A35: saved recovery selection consumed; next ordinary power-on selects normal boot.");
    return 0;
fail:
    if (fd >= 0) close(fd);
    report("A35: cannot validate or update boot selection; inspect recovery log.");
    return 1;
}
