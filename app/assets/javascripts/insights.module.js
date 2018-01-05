/*global angular*/
(function () {
  "use strict";
  var app = angular.module('RedhatAccessInsights', ['ui.router', 'insights']);


  app.config(['$httpProvider', '$locationProvider', '$urlRouterProvider', 'InsightsConfigProvider', '$provide',
    function ($httpProvider, $locationProvider, $urlRouterProvider, InsightsConfigProvider, $provide) {
      var token = document.getElementsByTagName('meta')['csrf-token'].getAttribute('content');
      $httpProvider.defaults.headers.common = {
        'X-CSRF-Token': token
      };
      $provide.factory('AuthInterceptor', ['$injector',
        function ($injector) {
          return {
            responseError: function (response) {
              var $q = $injector.get('$q');
              var $window = $injector.get('$window');
              if (response.status === 401) {
                $window.location.reload();
              } else if (response.status === 403) {
                $window.location.reload();
              }else if (response.status === 502) {
                $window.location.href = '/redhat_access/insights/configure';
              }
              return $q.reject(response);
            }
          };
        }
      ]);
      $httpProvider.interceptors.push('AuthInterceptor');
      $urlRouterProvider.otherwise('/overview')
      $locationProvider.html5Mode(true);
      InsightsConfigProvider.setApiPrefix('/redhat_access/r/insights/');
      InsightsConfigProvider.setGettingStartedLink('https://access.redhat.com/insights/getting-started/cloudforms/');
      InsightsConfigProvider.setPlannerEnabled(false);
      InsightsConfigProvider.setAllowExport(true);
    }
  ]);
}());