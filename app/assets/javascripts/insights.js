/*global angular*/
(function() {
    "use strict";
    var app = angular.module('RedhatAccessInsights', ['ui.router', 'insights']);


    app.config(['$locationProvider','$urlRouterProvider', 'InsightsConfigProvider',
        function($locationProvider, $urlRouterProvider, InsightsConfigProvider) {
            $urlRouterProvider.otherwise('/overview')
            $locationProvider.html5Mode(true);
            InsightsConfigProvider.setApiRoot('/redhat_access/r/insights/');
        }
    ]);
    
}());