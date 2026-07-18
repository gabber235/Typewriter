import "package:flutter/material.dart";

class ModalHeader extends StatelessWidget {
  const ModalHeader({
    this.title,
    this.onClose,
    super.key,
  });

  final String? title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (title != null && title!.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose ?? () => Navigator.of(context).pop(),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}
