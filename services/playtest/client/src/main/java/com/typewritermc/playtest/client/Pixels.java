package com.typewritermc.playtest.client;

/**
 * The colour of every pixel of a drawn frame, read back from the GPU: {@code rgba} holds the rows from
 * the bottom up, as the render target stores them, one int per pixel with red in the lowest byte.
 */
record Pixels(int width, int height, int[] rgba) {
    Pixels {
        if (rgba.length != width * height) throw new IllegalArgumentException(width + "x" + height + " pixels need " + width * height + " values, not " + rgba.length);
    }

    /**
     * How many pixels show another colour on screen in {@code other}, a frame of the same size. Alpha
     * never reaches the screen, so a pixel that differs only in alpha shows the same.
     */
    int differences(Pixels other) {
        if (width != other.width || height != other.height) throw new IllegalArgumentException("a " + width + "x" + height + " frame differs from a " + other.width + "x" + other.height + " one in size");
        int differing = 0;
        for (int index = 0; index < rgba.length; index++) {
            if (((rgba[index] ^ other.rgba[index]) & 0x00FFFFFF) != 0) differing++;
        }
        return differing;
    }

    /** The share of this frame's pixels that show another colour on screen in {@code other}, from 0 to 1. */
    double differingShare(Pixels other) {
        return (double) differences(other) / rgba.length;
    }
}
