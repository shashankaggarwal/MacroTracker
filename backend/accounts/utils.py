from django.http import Http404
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status

def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    
    if response is None:
        if isinstance(exc, Http404):
            return Response({'detail': 'Not found.'}, status=status.HTTP_404_NOT_FOUND)
        else:
            return Response({'detail': 'Unhandled server error'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
    return response
