import React from "react";
import clsx from "clsx";
import type { Props } from "@theme/MDXComponents/Img";
import Admonition from "@theme/Admonition";
import styles from "./styles.module.css";

function transformImgClassName(className?: string): string {
  return clsx(className, styles.img);
}

export default function MDXImg(props: Props): JSX.Element {
  // If the type is not gif. We should use the Image component
  if (!(props.src ?? "").endsWith(".gif")) {
    return (
      <Admonition type="danger" title="Invalid image">
        Image component not found, please report this in the{" "}
        <a href="https://discord.gg/gs5QYhfv9x">Typewriter Discord</a>.
      </Admonition>
    );
  }
  return (
    // eslint-disable-next-line jsx-a11y/alt-text
    <img
      decoding="async"
      loading="lazy"
      {...props}
      className={transformImgClassName(props.className)}
    />
  );
}
