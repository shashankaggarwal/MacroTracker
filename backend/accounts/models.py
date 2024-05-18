from django.db import models
from django.contrib.auth.models import AbstractUser
from django.core.validators import MinValueValidator
from django.core.exceptions import ValidationError
from django.utils import timezone
from simple_history.models import HistoricalRecords
from decimal import Decimal

class CustomUser(AbstractUser):
    pass

class Profile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE)
    calorie_goal = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    carbs_goal = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    protein_goal = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    fat_goal = models.IntegerField(default=0, validators=[MinValueValidator(0)])
    history = HistoricalRecords()

    def __str__(self):
        return f"{self.user.username}'s Profile"

class FoodItem(models.Model):
    name = models.CharField(max_length=255)
    calories_per_unit = models.DecimalField(max_digits=6, decimal_places=2, validators=[MinValueValidator(Decimal('0.00'))])
    carbs_per_unit = models.DecimalField(max_digits=6, decimal_places=2, validators=[MinValueValidator(Decimal('0.00'))])
    proteins_per_unit = models.DecimalField(max_digits=6, decimal_places=2, validators=[MinValueValidator(Decimal('0.00'))])
    fats_per_unit = models.DecimalField(max_digits=6, decimal_places=2, validators=[MinValueValidator(Decimal('0.00'))])
    history = HistoricalRecords()

    def __str__(self):
        return self.name

class FoodLog(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    food_item = models.ForeignKey(FoodItem, on_delete=models.CASCADE)
    quantity = models.DecimalField(max_digits=5, decimal_places=2, validators=[MinValueValidator(0)])
    meal_type = models.CharField(max_length=100, choices=[
        ('breakfast', 'Breakfast'),
        ('lunch', 'Lunch'),
        ('dinner', 'Dinner'),
        ('snack', 'Snack'),
    ])
    notes = models.TextField(blank=True, null=True)
    date_logged = models.DateTimeField(default=timezone.now)
    history = HistoricalRecords()

    class Meta:
        ordering = ['date_logged']  # Ensures default ordering by date_logged

    def calculate_total_calories(self):
        return (self.quantity / 100) * self.food_item.calories_per_unit

    def calculate_total_carbs(self):
        return (self.quantity / 100) * self.food_item.carbs_per_unit

    def calculate_total_proteins(self):
        return (self.quantity / 100) * self.food_item.proteins_per_unit

    def calculate_total_fats(self):
        return (self.quantity / 100) * self.food_item.fats_per_unit

    def save(self, *args, **kwargs):
        if self.date_logged > timezone.now():
            raise ValidationError("The log date cannot be in the future.")
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.user.username}'s Food Log on {self.date_logged.strftime('%Y-%m-%d %H:%M:%S')}"

class Notification(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    message = models.TextField()
    notification_type = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Notification for {self.user.username}"

class Insight(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    insight_type = models.CharField(max_length=100)
    value = models.TextField()
    generated_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Insight for {self.user.username}"
