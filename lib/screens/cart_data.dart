// cart_data.dart

List<Map<String, dynamic>> cartItems = [];

void addToCartItem({
  required String name,
  required int qty,
  required String note,
  required int tableNumber,
}) {
  cartItems.add({
    "name": name,
    "qty": qty,
    "note": note,
    "table": tableNumber,
  });
}

void removeFromCart(int index) {
  cartItems.removeAt(index);
}

void updateCartQuantity(int index, int newQty) {
  cartItems[index]["qty"] = newQty;
}

void clearCart() {
  cartItems.clear();
}
