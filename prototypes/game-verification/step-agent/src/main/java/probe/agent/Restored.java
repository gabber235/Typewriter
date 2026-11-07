package probe.agent;

/** Main class given at restore: `dir=/abs/server` and `-Dkey=value` arguments, applied before the boot continues. */
public final class Restored {
    private Restored() {}

    public static void main(String[] args) {
        for (String a : args) {
            if (a.startsWith("dir=")) Crac.dir = a.substring(4);
            else if (a.startsWith("-D") && a.contains("=")) {
                int i = a.indexOf('=');
                System.setProperty(a.substring(2, i), a.substring(i + 1));
            }
        }
        System.err.println("[crac] restore args applied: " + String.join(" ", args));
    }
}
