import 'package:flutter/material.dart';
import 'package:product_management/models/product.dart';
import 'package:product_management/providers/product_provider.dart';
import 'package:provider/provider.dart';
import 'add_product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<void> _productsFuture;
  final Map<String, bool> _expandedCards = {};
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    _productsFuture = provider.fetchProducts();
    await _productsFuture;
    _filteredProducts = provider.products;
  }

  void _toggleCardExpansion(String productId) {
    setState(() {
      _expandedCards[productId] = !(_expandedCards[productId] ?? false);
    });
  }

  void _deleteProduct(String productId) async {
    try {
      await Provider.of<ProductProvider>(context, listen: false).deleteProduct(productId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
      _loadProducts();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $error')),
      );
    }
  }

  void _filterProducts(String query) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    setState(() {
      _filteredProducts = provider.products.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.price.toString().contains(query);
      }).toList();
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filterProducts('');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search iMac, Apple Watch...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                ),
                onChanged: _filterProducts,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.apple, size: 28, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'iVerse',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
        actions: [
          _isSearching
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _toggleSearch,
                )
              : IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _toggleSearch,
                ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Home'),
            Tab(icon: Icon(Icons.edit), text: 'Edit'),
            Tab(icon: Icon(Icons.add), text: 'Add'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHomeTab(),
          _buildEditTab(),
          const AddProductScreen(),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final provider = Provider.of<ProductProvider>(context);
    final productsToShow = _isSearching ? _filteredProducts : provider.products;

    return FutureBuilder(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
        }
        if (productsToShow.isEmpty) {
          return Center(
            child: Text(
              _isSearching ? 'No matching products found' : 'No products available',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: productsToShow.length,
          itemBuilder: (ctx, index) => _buildProductCard(productsToShow[index]),
        );
      },
    );
  }

  Widget _buildEditTab() {
    final provider = Provider.of<ProductProvider>(context);

    return FutureBuilder(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (provider.products.isEmpty) {
          return const Center(child: Text('No products to edit', style: TextStyle(color: Colors.white)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.products.length,
          itemBuilder: (ctx, index) {
            final product = provider.products[index];
            return Card(
              color: Colors.grey[900],
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: Text(product.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70)),
                trailing: const Icon(Icons.edit, color: Colors.white),
                onTap: () => Navigator.pushNamed(context, '/edit', arguments: product.id),
                onLongPress: () => _deleteProduct(product.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      color: Colors.grey[900],
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 1,
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, error, stackTrace) =>
                          Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.white, size: 40),
                            ),
                          ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(Icons.photo, color: Colors.white, size: 40),
                      ),
                    ),
            ),
          ),

          // Product Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}