from django.contrib.auth import get_user_model
from rest_framework import serializers
from .models import Profile, FoodItem, FoodLog, Notification, Insight
from simple_history.models import HistoricalRecords
from django.utils import timezone
from datetime import timedelta


User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, style={'input_type': 'password'})

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'password', 'is_staff', 'is_active', 'date_joined']
        read_only_fields = ['id', 'is_staff', 'is_active', 'date_joined']

    def create(self, validated_data):
        user = User.objects.create(
            username=validated_data['username'],
            email=validated_data['email']
        )
        user.set_password(validated_data['password'])
        user.save()
        return user

class ProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)
    is_staff = serializers.BooleanField(source='user.is_staff', read_only=True)
    is_active = serializers.BooleanField(source='user.is_active', read_only=True)
    date_joined = serializers.DateTimeField(source='user.date_joined', read_only=True)
    user_id = serializers.IntegerField(source='user.id', read_only=True)

    class Meta:
        model = Profile
        fields = [
            'user_id', 'id', 'username', 'email', 'is_staff', 'is_active',
            'date_joined', 'calorie_goal', 'carbs_goal', 'protein_goal', 'fat_goal'
        ]

class FoodItemSerializer(serializers.ModelSerializer):
    history = serializers.SerializerMethodField()

    class Meta:
        model = FoodItem
        fields = ['id', 'name', 'calories_per_unit', 'carbs_per_unit', 'proteins_per_unit', 'fats_per_unit', 'history']

    def get_history(self, obj):
        history = obj.history.all()
        history_data = []
        for h in history:
            if h.prev_record:
                changes = h.prev_record.diff_against(h)
                history_entry = {
                    'changed_by': h.history_user,
                    'change_date': h.history_date,
                    'old_values': {change.field: change.old for change in changes.changes}
                }
            else:
                history_entry = {
                    'changed_by': h.history_user,
                    'change_date': h.history_date,
                    'old_values': []
                }
            history_data.append(history_entry)
        return history_data

class FoodLogSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    food_item_id = serializers.PrimaryKeyRelatedField(
        queryset=FoodItem.objects.all(), source='food_item', write_only=True
    )
    food_item_name = serializers.CharField(source='food_item.name', read_only=True)
    total_calories = serializers.SerializerMethodField(read_only=True)
    total_carbs = serializers.SerializerMethodField(read_only=True)
    total_proteins = serializers.SerializerMethodField(read_only=True)
    total_fats = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = FoodLog
        fields = [
            'id', 'username', 'food_item_id', 'food_item_name', 'quantity', 'meal_type', 
            'date_logged', 'notes', 'total_calories', 'total_carbs', 'total_proteins', 'total_fats'
        ]
        read_only_fields = [
            'id', 'username', 'food_item_name', 'total_calories', 'total_carbs', 'total_proteins', 'total_fats'
        ]

    def validate_date_logged(self, value):
        if value > timezone.now() + timedelta(minutes=5):
            raise serializers.ValidationError("The log date cannot be in the future.")
        return value

    def get_total_calories(self, obj):
        return obj.calculate_total_calories()

    def get_total_carbs(self, obj):
        return obj.calculate_total_carbs()

    def get_total_proteins(self, obj):
        return obj.calculate_total_proteins()

    def get_total_fats(self, obj):
        return obj.calculate_total_fats()



class NotificationSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = Notification
        fields = ['id', 'username', 'message', 'notification_type', 'created_at']
        read_only_fields = ['id', 'created_at']

class InsightSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = Insight
        fields = ['id', 'username', 'insight_type', 'value', 'generated_at']
        read_only_fields = ['id', 'generated_at']
