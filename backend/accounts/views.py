from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import viewsets, permissions, filters
from rest_framework.pagination import PageNumberPagination
from .models import CustomUser, Profile, FoodItem, FoodLog, Notification, Insight
from .serializers import (UserSerializer, ProfileSerializer, FoodItemSerializer,
                          FoodLogSerializer, NotificationSerializer, InsightSerializer)
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
import logging
from rest_framework_simplejwt.tokens import RefreshToken
from django.utils.timezone import make_aware
from datetime import datetime, timedelta
from django.utils.timezone import make_aware, datetime

logger = logging.getLogger(__name__)


class StandardResultsSetPagination(PageNumberPagination):
    page_size = 30
    page_size_query_param = 'page_size'
    max_page_size = 100

class UserViewSet(viewsets.ModelViewSet):
    queryset = CustomUser.objects.all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAdminUser]

    def get_permissions(self):
        if self.request.method == 'POST':
            self.permission_classes = [AllowAny]
        return super(UserViewSet, self).get_permissions()

    def create(self, request, *args, **kwargs):
        logger.debug("Creating a new user with data: %s", request.data)
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        profile = Profile.objects.get(user=user)
        profile_serializer = ProfileSerializer(profile)

        refresh = RefreshToken.for_user(user)

        response_data = serializer.data
        response_data['profile'] = profile_serializer.data
        response_data['access'] = str(refresh.access_token)
        response_data['refresh'] = str(refresh)

        headers = self.get_success_headers(serializer.data)
        return Response(response_data, status=status.HTTP_201_CREATED, headers=headers)

class ProfileViewSet(viewsets.ModelViewSet):
    queryset = Profile.objects.all()
    serializer_class = ProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter]
    search_fields = ['user__username']

    def get_queryset(self):
        if self.request.user.is_superuser:
            return Profile.objects.all()
        return Profile.objects.filter(user=self.request.user)

class FoodItemViewSet(viewsets.ModelViewSet):
    queryset = FoodItem.objects.all()
    serializer_class = FoodItemSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['name']
    search_fields = ['name', 'calories_per_unit']

    def create(self, request, *args, **kwargs):
        try:
            response = super().create(request, *args, **kwargs)
            logger.debug("Food item created successfully with data: %s", request.data)
            return response
        except Exception as e:
            logger.error("Error in creating food item: %s", str(e), exc_info=True)
            return Response({"detail": "Internal server error"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class FoodLogViewSet(viewsets.ModelViewSet):
    serializer_class = FoodLogSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['meal_type', 'food_item__name']
    search_fields = ['food_item__name', 'notes']
    ordering_fields = ['date_logged', 'food_item__name']
    pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        queryset = FoodLog.objects.filter(user=self.request.user)
        date = self.request.query_params.get('date')
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')

        if date:
            day_start = make_aware(datetime.strptime(date, '%Y-%m-%d'))
            day_end = day_start + timedelta(days=1)
            queryset = queryset.filter(date_logged__gte=day_start, date_logged__lt=day_end)
        elif start_date and end_date:
            start_date = make_aware(datetime.strptime(start_date, '%Y-%m-%d'))
            end_date = make_aware(datetime.strptime(end_date, '%Y-%m-%d')) + timedelta(days=1)
            queryset = queryset.filter(date_logged__gte=start_date, date_logged__lt=end_date)
        return queryset

    def list(self, request, *args, **kwargs):
        if 'date' in request.query_params:
            queryset = self.filter_queryset(self.get_queryset())
            serializer = self.get_serializer(queryset, many=True)
            return Response(serializer.data)
        return super().list(request, *args, **kwargs)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def retrieve(self, request, *pk, **kwargs):
        logger.debug(f"Retrieving FoodLog item with ID: {kwargs.get('pk')}")
        return super().retrieve(request, *pk, **kwargs)

    def update(self, request, *args, **kwargs):
        logger.debug(f"Updating FoodLog item with ID: {kwargs.get('pk')}")
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        logger.debug(f"Deleting FoodLog item with ID: {kwargs.get('pk')}")
        return super().destroy(request, *args, **kwargs)

class NotificationViewSet(viewsets.ModelViewSet):
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if self.request.user.is_superuser:
            return Notification.objects.all()
        return Notification.objects.filter(user=self.request.user)

class InsightViewSet(viewsets.ModelViewSet):
    queryset = Insight.objects.all()
    serializer_class = InsightSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if self.request.user.is_superuser:
            return Insight.objects.all()
        return Insight.objects.filter(user=self.request.user)
