import { z } from "zod";

/** Transport generator options from skir.yml; the target language comes from the module export. */
export const Config = z
  .object({
    /** Path of the transport route manifest, relative to the Skir project root. */
    manifest: z.string().min(1),
    /** Package URI prefix of the Dart Skir output, required by the Dart target. */
    dartImportUriPrefix: z.string().min(1).optional(),
  })
  .strict();

export type Config = z.infer<typeof Config>;
