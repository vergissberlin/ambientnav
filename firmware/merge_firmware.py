"""Merge bootloader, partition table, and app into a single flash image."""

Import("env")

APP_BIN = "$BUILD_DIR/${PROGNAME}.bin"
MERGED_BIN = "$BUILD_DIR/${PROGNAME}-merged.bin"
BOARD_CONFIG = env.BoardConfig()


def _flash_freq() -> str:
    freq = str(BOARD_CONFIG.get("build.f_flash", "40000000L")).replace("L", "")
    return f"{int(int(freq) / 1_000_000)}m"


def _flash_mode() -> str:
    mode = BOARD_CONFIG.get("build.flash_mode", "dio")
    memory_type = BOARD_CONFIG.get("build.arduino.memory_type", "qio_qspi")

    if mode in ("qio", "qout"):
        mode = "dio"
    if memory_type in ("opi_opi", "opi_qspi"):
        mode = "dout"
    return mode


def merge_bin(source, target, env):
    flash_images = env.Flatten(env.get("FLASH_EXTRA_IMAGES", [])) + [
        "$ESP32_APP_OFFSET",
        APP_BIN,
    ]

    env.Execute(
        " ".join(
            [
                '"$PYTHONEXE"',
                '"$OBJCOPY"',
                "--chip",
                BOARD_CONFIG.get("build.mcu", "esp32"),
                "merge_bin",
                "--flash_mode",
                _flash_mode(),
                "--flash_freq",
                _flash_freq(),
                "--flash_size",
                BOARD_CONFIG.get("upload.flash_size", "4MB"),
                "-o",
                MERGED_BIN,
            ]
            + flash_images
        )
    )


env.AddPostAction(APP_BIN, merge_bin)

env.AddCustomTarget(
    name="mergebin",
    dependencies=APP_BIN,
    actions=merge_bin,
    title="Merge firmware",
    description="Merge bootloader, partitions, and app into firmware-merged.bin",
)
