import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'kot_data.dart';
import 'cart_data.dart';

class OrderScreen extends StatefulWidget {
  final String foodName;
  final String imagePath;
  final String price;
  final String description;
  final int tableNumber;

  const OrderScreen({
    super.key,
    required this.foodName,
    required this.imagePath,
    required this.price,
    required this.description,
    required this.tableNumber,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int quantity = 1;
  late TextEditingController _tableController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _tableController = TextEditingController(text: widget.tableNumber.toString());
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _tableController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void addToCart() {
    int tableNo = int.tryParse(_tableController.text) ?? widget.tableNumber;
    String note = _noteController.text;

    addToCartItem(
      name: widget.foodName,
      qty: quantity,
      note: note,
      tableNumber: tableNo,
    );

    Fluttertoast.showToast(
      msg: "Added to cart for Table $tableNo",
      backgroundColor: Colors.black,
      textColor: Colors.white,
    );

    setState(() {
      quantity = 1;
      _noteController.clear();
    });
  }

  void showCartModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, modalSetState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Cart", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(),
                if (cartItems.isEmpty)
                  const Text("No items in cart.")
                else
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return ListTile(
                        title: Text("${item['name']} (x${item['qty']})"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Note: ${item['note'] ?? ''}"),
                            Text("Table: ${item['table']}"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (item['qty'] > 1) {
                                  modalSetState(() {
                                    updateCartQuantity(index, item['qty'] - 1);
                                  });
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                modalSetState(() {
                                  updateCartQuantity(index, item['qty'] + 1);
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                modalSetState(() {
                                  removeFromCart(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: cartItems.isEmpty ? null : submitKOT,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Submit KOT"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void submitKOT() async {
    final grouped = <int, List<String>>{};

    for (var item in cartItems) {
      int table = item['table'];
      grouped.putIfAbsent(table, () => []);
      grouped[table]!.add("${item['name']} x${item['qty']} (${item['note']})");
    }

    for (var entry in grouped.entries) {
      int table = entry.key;
      List<String> items = entry.value;

      // 🔄 Submit via API instead of local save
      await createKOT(table, items, status: 'Pending');
    }

    Fluttertoast.showToast(msg: "KOT submitted for ${grouped.keys.length} table(s)");
    clearCart();

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    double unitPrice = double.tryParse(widget.price) ?? 0.0;
    double totalPrice = unitPrice * quantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Place Order"),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: showCartModal,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.imagePath,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 100),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.foodName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.description, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _tableController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Table Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: "Add a note (optional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Quantity", style: TextStyle(fontSize: 18)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        if (quantity > 1) {
                          setState(() => quantity--);
                        }
                      },
                    ),
                    Text(quantity.toString(), style: const TextStyle(fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        setState(() => quantity++);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text("Total: Rs. ${totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            ElevatedButton(
              onPressed: addToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("Add to Cart"),
            ),
          ],
        ),
      ),
    );
  }
}
