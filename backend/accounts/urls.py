from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UserViewSet, ProfileViewSet, FoodItemViewSet, FoodLogViewSet, NotificationViewSet, InsightViewSet

router = DefaultRouter()
router.register(r'users', UserViewSet)
router.register(r'profiles', ProfileViewSet)
router.register(r'food_items', FoodItemViewSet)
router.register(r'food_logs', FoodLogViewSet, basename='foodlog')
router.register(r'notifications', NotificationViewSet)
router.register(r'insights', InsightViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
