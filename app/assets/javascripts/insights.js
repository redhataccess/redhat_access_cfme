/*global angular*/
(function() {
  "use strict";
  var app = angular.module('RedhatAccessInsights', ['ui.router', 'insights']);


  app.config(['$httpProvider','$locationProvider', '$urlRouterProvider', 'InsightsConfigProvider',
    function($httpProvider,$locationProvider, $urlRouterProvider, InsightsConfigProvider) {
      var token = document.getElementsByTagName('meta')['csrf-token'].getAttribute('content');
      $httpProvider.defaults.headers.common = {
        'X-CSRF-Token': token
      };
      $urlRouterProvider.otherwise('/overview')
      $locationProvider.html5Mode(true);
      InsightsConfigProvider.setApiRoot('/redhat_access/r/insights/');
      InsightsConfigProvider.setGettingStartedLink('https://access.redhat.com/insights/getting-started/');
    }
  ]);
}());
