libext4_utils_src_files := \
	make_ext4fs.c \
	make_ext4fs_main.c \
	ext4_utils.c \
	allocate.c \
	backed_block.c \
	output_file.c \
	contents.c \
	extent.c \
	indirect.c \
	uuid.c \
	sha1.c \
	sparse_crc32.c

libext4_utils_src_obj := $(libext4_utils_src_files:.c=.o)

simg2img_src_files := \
	simg2img.c \
	sparse_crc32.c

simg2img_src_obj := $(simg2img_src_files:.c=.o)

all: make_ext4fs simg2img

%.o: %.c
	gcc -I. -DANDROID -c $<

make_ext4fs: $(libext4_utils_src_obj)
	gcc $^ -o $@ -lz


simg2img: $(simg2img_src_obj)
	gcc $^ -o $@

.PHONY: clean
clean:
	rm -rf *.o make_ext4fs simg2img
