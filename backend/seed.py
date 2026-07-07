from app import create_app, db
from app.models.user import User, Role
from app.models.category import Category
from app.models.product import Product
from app.models.temper_glass import TemperBox, TemperBoxItem
from app.models.activity_log import ActivityLog

app = create_app()

with app.app_context():
    print("🔧 Creating all tables...")
    
    # This creates ALL tables directly in Supabase
    db.create_all()
    print("✅ All tables created in Supabase!")

    print("\n🌱 Seeding data...")

    # Create roles
    if not Role.query.first():
        admin_role = Role(name='admin')
        staff_role = Role(name='staff')
        db.session.add_all([admin_role, staff_role])
        db.session.commit()
        print("✅ Roles created: admin, staff")
    else:
        print("⏭️  Roles already exist")

    # Create default categories
    default_categories = [
        {'name': 'Mobile Covers',  'slug': 'mobile-covers',  'icon': 'phone_android', 'is_default': True},
        {'name': 'Earphones',      'slug': 'earphones',      'icon': 'headphones',    'is_default': True},
        {'name': 'Earbuds',        'slug': 'earbuds',        'icon': 'earbuds',       'is_default': True},
        {'name': 'Chargers',       'slug': 'chargers',       'icon': 'electric_bolt', 'is_default': True},
        {'name': 'Charger Cables', 'slug': 'charger-cables', 'icon': 'cable',         'is_default': True},
        {'name': 'Temper Glass',   'slug': 'temper-glass',   'icon': 'smartphone',    'is_default': True},
        {'name': 'Others',         'slug': 'others',         'icon': 'category',      'is_default': True},
    ]

    if not Category.query.first():
        for cat in default_categories:
            category = Category(**cat)
            db.session.add(category)
        db.session.commit()
        print("✅ 7 default categories created")
    else:
        print("⏭️  Categories already exist")

    # Create admin user
    admin_role = Role.query.filter_by(name='admin').first()
    if not User.query.filter_by(username='admin').first():
        admin = User(
            username='admin',
            full_name='SR Mobiles Admin',
            role_id=admin_role.id
        )
        admin.set_password('admin123')
        db.session.add(admin)
        db.session.commit()
        print("✅ Admin user created — username: admin | password: admin123")
    else:
        print("⏭️  Admin already exists")

    # Create staff user
    staff_role = Role.query.filter_by(name='staff').first()
    if not User.query.filter_by(username='staff').first():
        staff = User(
            username='staff',
            full_name='SR Mobiles Staff',
            role_id=staff_role.id
        )
        staff.set_password('staff123')
        db.session.add(staff)
        db.session.commit()
        print("✅ Staff user created — username: staff | password: staff123")
    else:
        print("⏭️  Staff already exists")

    print("\n🎉 Database ready!")
    print("\n📋 Login credentials:")
    print("   Admin → username: admin | password: admin123")
    print("   Staff → username: staff | password: staff123")