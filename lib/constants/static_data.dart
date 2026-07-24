class StaticData {
  static const List<Map<String, dynamic>> products = [
    {
      'name': 'Coca Cola',
      'price': 40.0,
      'category': 'Drinks',
      'image': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=300&q=80',
    },
    {
      'name': 'Pepsi',
      'price': 40.0,
      'category': 'Drinks',
      'image': 'https://images.unsplash.com/photo-1629203851122-3726ecdf080e?w=300&q=80',
    },
    {
      'name': 'Sprite',
      'price': 40.0,
      'category': 'Drinks',
      'image': 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=300&q=80',
    },
    {
      'name': 'Orange Juice',
      'price': 60.0,
      'category': 'Drinks',
      'image': 'https://images.unsplash.com/photo-1600271886742-f049cd451b51?w=300&q=80',
    },
    {
      'name': 'Cold Coffee',
      'price': 80.0,
      'category': 'Drinks',
      'image': 'https://images.unsplash.com/photo-1461023058943-0708e5211927?w=300&q=80',
    },
    {
      'name': 'French Fries',
      'price': 120.0,
      'category': 'Snacks',
      'image': 'https://images.unsplash.com/photo-1576107232684-1279f390859f?w=300&q=80',
    },
    {
      'name': 'Chicken Burger',
      'price': 150.0,
      'category': 'Snacks',
      'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300&q=80',
    },
    {
      'name': 'Veg Sandwich',
      'price': 90.0,
      'category': 'Snacks',
      'image': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=300&q=80',
    },
    {
      'name': 'Chicken Nuggets',
      'price': 130.0,
      'category': 'Snacks',
      'image': 'https://images.unsplash.com/photo-1562967914-608f82629710?w=300&q=80',
    },
    {
      'name': 'Chicken Biryani',
      'price': 250.0,
      'category': 'Meals',
      'image': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300&q=80',
    },
    {
      'name': 'Meals',
      'price': 100.0,
      'category': 'Meals',
      'image': 'https://images.unsplash.com/photo-1626776876729-bab4369a5a5a?w=300&q=80',
    },
    {
      'name': 'Veg Fried Rice',
      'price': 180.0,
      'category': 'Meals',
      'image': 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=300&q=80',
    },
    {
      'name': 'Paneer Butter Masala',
      'price': 220.0,
      'category': 'Meals',
      'image': 'https://images.unsplash.com/photo-1589301760014-d929f39ce9b1?w=300&q=80',
    },
    {
      'name': 'Chocolate Ice Cream',
      'price': 80.0,
      'category': 'Desserts',
      'image': 'https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=300&q=80',
    },
    {
      'name': 'Donut',
      'price': 60.0,
      'category': 'Desserts',
      'image': 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=300&q=80',
    },
    {
      'name': 'Cheesecake',
      'price': 150.0,
      'category': 'Desserts',
      'image': 'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=300&q=80',
    },
    {
      'name': 'Brownie',
      'price': 110.0,
      'category': 'Desserts',
      'image': 'https://images.unsplash.com/photo-1606890737304-57a1ca8a5b62?w=300&q=80',
    },
  ];

  static String getImageForProduct(String name) {
    try {
      final product = products.firstWhere((p) => p['name'] == name);
      return product['image'] as String;
    } catch (e) {
      // Fallback image
      return 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=300&q=80';
    }
  }
}
