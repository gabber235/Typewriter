package com.typewritermc.playtest.client;

/**
 * The mouse motion a person makes to turn the view onto a point, from the game's own turn rule: a
 * pixel of motion turns the view by {@link #degreesPerPixel} degrees, yaw to the right for positive x
 * and pitch down for positive y.
 */
final class Aim {
    private Aim() {}

    /** Motion in pixels, x then y. */
    record Motion(double x, double y) {}

    /** The view's direction in degrees: yaw 0 looks south (+z), pitch 90 straight down. */
    record Direction(double yaw, double pitch) {}

    /** Degrees the view turns per pixel of motion at {@code sensitivity}, the game's mouse sensitivity from 0 to 1. */
    static double degreesPerPixel(double sensitivity) {
        double scaled = sensitivity * 0.6 + 0.2;
        return scaled * scaled * scaled * 8.0 * 0.15;
    }

    /** The direction from {@code eye} to {@code target}, each as x, y, z. */
    static Direction toward(double eyeX, double eyeY, double eyeZ, double targetX, double targetY, double targetZ) {
        double dx = targetX - eyeX;
        double dy = targetY - eyeY;
        double dz = targetZ - eyeZ;
        double yaw = Math.toDegrees(Math.atan2(-dx, dz));
        double pitch = Math.toDegrees(-Math.atan2(dy, Math.sqrt(dx * dx + dz * dz)));
        return new Direction(yaw, pitch);
    }

    /**
     * The motion that turns the view from {@code from} to {@code to} the short way round. The game
     * keeps pitch within plus and minus 90, so a target beyond that is aimed at the limit.
     */
    static Motion motion(Direction from, Direction to, double degreesPerPixel) {
        double yaw = wrap(to.yaw() - from.yaw());
        double pitch = Math.max(-90, Math.min(90, to.pitch())) - from.pitch();
        return new Motion(yaw / degreesPerPixel, pitch / degreesPerPixel);
    }

    /** An angle in degrees brought into minus 180 (exclusive) to 180. */
    static double wrap(double degrees) {
        double wrapped = degrees % 360;
        if (wrapped <= -180) wrapped += 360;
        if (wrapped > 180) wrapped -= 360;
        return wrapped;
    }
}
