from django.contrib import admin
from django.urls import path, include, re_path
from django.views.generic import RedirectView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('accounts.urls')),
    path('api/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    re_path(r'^$', RedirectView.as_view(url='/admin/', permanent=False)),  # Redirect root to /admin/
    path('api/password_reset/', include('django.contrib.auth.urls')),  # Include Django's default password reset URLs
    
]
