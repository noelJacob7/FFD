import 'package:flutter/material.dart';

class CustomSearchAnchor extends StatelessWidget {
  final SearchController searchController;
  final Future<List<dynamic>>? sequencesFuture; // Update 'dynamic' to your actual sequence model type
  final VoidCallback onRefresh;
  final VoidCallback onClear;
  final Function(dynamic) onSequenceSelected; // Update 'dynamic' to your actual sequence model type

  const CustomSearchAnchor({
    super.key,
    required this.searchController,
    required this.sequencesFuture,
    required this.onRefresh,
    required this.onClear,
    required this.onSequenceSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      searchController: searchController,
      viewShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      viewConstraints: const BoxConstraints(maxHeight: 300),
      viewLeading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          searchController.closeView(searchController.text);
        },
      ),
      viewTrailing: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Fetch New Sequences',
          onPressed: () {
            onRefresh();
            searchController.closeView(searchController.text);
            Future.delayed(const Duration(milliseconds: 50), () {
              if (context.mounted) searchController.openView();
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            searchController.clear();
            onClear();
            searchController.closeView('');
          },
        ),
      ],
      builder: (context, controller) {
        return SearchBar(
          controller: controller,
          elevation: const WidgetStatePropertyAll(0),
          readOnly: true,
          leading: const Icon(Icons.search),
          hintText: 'Select a sequence...',
          onTap: () => controller.openView(),
          onChanged: (_) => controller.openView(),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      },
      suggestionsBuilder: (context, controller) async {
        try {
          final sequences = await (sequencesFuture ?? Future.value([]));

          return sequences.map(
            (data) => ListTile(
              title: Text(data.id),
              subtitle: Text('Original Label: ${data.label}'),
              onTap: () => onSequenceSelected(data),
            ),
          ).toList(); // Make sure to add .toList() here so the Iterable becomes a List<Widget>
        } catch (e) {
          return [
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    color: Colors.redAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load sequences.\nPlease check your connection.\n\nClick the refresh button above to try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          ];
        }
      },
    ); // Added the missing semicolon here!
  }
}