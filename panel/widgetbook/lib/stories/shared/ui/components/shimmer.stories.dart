import "package:flutter/material.dart";
import "package:typewriter_panel/shared/ui/components/shimmer.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(name: "Shimmer Boxes", type: Shimmer)
Widget shimmerBoxUseCase(BuildContext context) {
  final width = context.knobs.double.slider(
    label: "Width",
    initialValue: 400,
    min: 50,
    max: 800,
  );
  final height = context.knobs.double.slider(
    label: "Height",
    initialValue: 200,
    min: 10,
    max: 800,
  );
  final borderRadius = context.knobs.double.slider(
    label: "Border Radius",
    initialValue: 8,
    min: 0,
    max: 50,
  );
  final shapeType = context.knobs.object.dropdown(
    label: "Shape",
    options: ["rectangle", "circle", "stadium", "custom"],
    labelBuilder: (shape) => shape,
    initialOption: "rectangle",
  );

  ShapeBorder shape;
  switch (shapeType) {
    case "circle":
      shape = const CircleBorder();
    case "stadium":
      shape = const StadiumBorder();
    case "custom":
      shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
      );
    case "rectangle":
    default:
      shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      );
  }

  return FakeApp(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(
          width: width,
          height: height,
          shape: shape,
        ),
      ],
    ),
  );
}

@widgetbook.UseCase(name: "Layout Example", type: Shimmer)
Widget shimmerLayoutUseCase(BuildContext context) {
  return FakeApp(
    child: ListView(
      shrinkWrap: true,
      children: [
        const SizedBox(height: 16),

        // Header section with circular avatars
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 6,
            itemBuilder: (context, index) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: ShimmerBox.circle(
                  width: 54,
                  height: 54,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),

        // Card-like items
        ...List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                ShimmerBox.rectangle(
                  width: double.infinity,
                  height: 200,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),

                const SizedBox(height: 16),

                // Text lines
                ShimmerBox.rectangle(
                  width: double.infinity,
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),

                const SizedBox(height: 8),

                ShimmerBox.rectangle(
                  width: 250,
                  height: 24,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),

                const SizedBox(height: 8),

                ShimmerBox.rectangle(
                  width: 180,
                  height: 20,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

@widgetbook.UseCase(name: "Custom Shapes", type: Shimmer)
Widget shimmerCustomShapesUseCase(BuildContext context) {
  return FakeApp(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom shaped container
          ShimmerLoading(
            child: Container(
              width: 300,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Row of different shapes
          Row(
            children: [
              const ShimmerBox.circle(
                width: 60,
                height: 60,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox.rectangle(
                      height: 20,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    const SizedBox(height: 8),
                    ShimmerBox.rectangle(
                      width: 150,
                      height: 16,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const ShimmerBox.stadium(
                width: 80,
                height: 32,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Grid of shimmer boxes
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return ShimmerBox.rectangle(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              );
            },
          ),
        ],
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Small Shapes List", type: Shimmer)
Widget shimmerSmallShapesListUseCase(BuildContext context) {
  return FakeApp(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(
          8,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ShimmerBox.rectangle(
              width: 60,
              height: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Shape Borders", type: Shimmer)
Widget shimmerShapeBordersUseCase(BuildContext context) {
  return FakeApp(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Various ShapeBorder Examples",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Row 1: Basic shapes
          Row(
            children: [
              Column(
                children: [
                  ShimmerBox.rectangle(
                    width: 80,
                    height: 60,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Rectangle",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  const ShimmerBox.circle(
                    width: 60,
                    height: 60,
                  ),
                  const SizedBox(height: 8),
                  Text("Circle", style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  const ShimmerBox.stadium(
                    width: 80,
                    height: 40,
                  ),
                  const SizedBox(height: 8),
                  Text("Stadium", style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Row 2: Custom border shapes
          Row(
            children: [
              Column(
                children: [
                  const ShimmerBox(
                    width: 80,
                    height: 60,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Custom Corners",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  const ShimmerBox(
                    width: 80,
                    height: 60,
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("Beveled", style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  const ShimmerBox(
                    width: 80,
                    height: 60,
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Continuous",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Row 3: Complex shapes
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Complex Shapes",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Card with notched corners
              ShimmerBox(
                width: double.infinity,
                height: 80,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              const SizedBox(height: 16),

              // Pill shape with different aspect ratio
              const ShimmerBox.stadium(
                width: 200,
                height: 30,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
