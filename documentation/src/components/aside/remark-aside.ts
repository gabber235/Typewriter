import type { Root } from 'mdast';
import type { Plugin } from 'unified';
import { visit } from 'unist-util-visit';
import {
  isAsideVariant,
  defaultTitles,
  icons,
  variantStyles,
  asideClasses,
} from './aside-config';

interface DirectiveNode {
  type: 'containerDirective' | 'leafDirective' | 'textDirective';
  name: string;
  attributes?: Record<string, string>;
  children: any[];
  data?: {
    directiveLabel?: boolean;
    hName?: string;
    hProperties?: Record<string, any>;
  };
}

function isDirective(node: any): node is DirectiveNode {
  return (
    node.type === 'containerDirective' ||
    node.type === 'leafDirective' ||
    node.type === 'textDirective'
  );
}

/**
 * Custom remark plugin that transforms directives like :::info, :::warning, :::danger, etc.
 * into custom styled aside elements with Tailwind classes.
 */
export const remarkAside: Plugin<[], Root> = () => {
  return (tree) => {
    visit(tree, (node: any, index, parent) => {
      if (!parent || index === undefined || !isDirective(node)) return;
      if (node.type === 'textDirective' || node.type === 'leafDirective') return;

      const variant = node.name;
      if (!isAsideVariant(variant)) return;

      // Extract custom title from directive label if present
      let title = defaultTitles[variant];
      const firstChild = node.children[0];
      if (
        firstChild?.type === 'paragraph' &&
        firstChild.data?.directiveLabel &&
        firstChild.children?.length > 0
      ) {
        // Extract text from label
        title = firstChild.children.map((c: any) => c.value || '').join('');
        node.children.splice(0, 1);
      }

      const styles = variantStyles[variant];

      // Create the aside structure using hast properties
      // Layout: container > header (icon + title) + content
      const aside = {
        type: 'paragraph',
        data: {
          hName: 'aside',
          hProperties: {
            class: `${asideClasses.container} ${styles.border} ${styles.bg}`,
          },
        },
        children: [
          {
            type: 'paragraph',
            data: {
              hName: 'div',
              hProperties: {
                class: asideClasses.header,
              },
            },
            children: [
              {
                type: 'html',
                value: `<span class="${asideClasses.icon} ${styles.text}">${icons[variant]}</span>`,
              },
              {
                type: 'paragraph',
                data: {
                  hName: 'p',
                  hProperties: {
                    class: `${asideClasses.title} ${styles.text}`,
                  },
                },
                children: [
                  {
                    type: 'text',
                    value: title,
                  },
                ],
              },
            ],
          },
          {
            type: 'paragraph',
            data: {
              hName: 'div',
              hProperties: {
                class: `${asideClasses.content} ${styles.text}`,
              },
            },
            children: node.children,
          },
        ],
      };

      parent.children[index] = aside as any;
    });
  };
};

export default remarkAside;
