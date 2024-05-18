from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser, Profile, FoodItem, FoodLog, Notification, Insight
from simple_history.admin import SimpleHistoryAdmin  # This is for integrating django-simple-history

# Register your models here.

@admin.register(CustomUser)
class CustomUserAdmin(UserAdmin):
    model = CustomUser
    list_display = ['username', 'email', 'is_staff']  # Customize as needed

@admin.register(Profile)
class ProfileAdmin(SimpleHistoryAdmin):  # Inherits from SimpleHistoryAdmin to manage historical records
    list_display = ['user', 'calorie_goal', 'carbs_goal', 'protein_goal', 'fat_goal']
    readonly_fields = ['user']  # Assuming you don't want to change the user from the admin

@admin.register(FoodItem)
class FoodItemAdmin(SimpleHistoryAdmin):
    list_display = ['name', 'calories_per_unit', 'carbs_per_unit', 'proteins_per_unit', 'fats_per_unit']
    readonly_fields = ['history']  # If history is implemented as a read-only field

@admin.register(FoodLog)
class FoodLogAdmin(SimpleHistoryAdmin):
    list_display = ['user', 'food_item', 'quantity', 'meal_type', 'date_logged']
    readonly_fields = ['user', 'date_logged']  # To prevent changes to user and log date from the admin

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['user', 'message', 'notification_type', 'created_at']
    readonly_fields = ['created_at']  # To keep track of when notifications were created without alteration

@admin.register(Insight)
class InsightAdmin(admin.ModelAdmin):
    list_display = ['user', 'insight_type', 'value', 'generated_at']
    readonly_fields = ['generated_at']  # To keep track of when insights were generated without alteration

# Additional configurations or adjustments as needed

