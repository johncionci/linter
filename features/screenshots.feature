@mink:browser
Feature: You can see the main features of the site
  In order to test the website
  As a QA engineer
  I need to take screenshots

  Background:
    Given the breakpoints:
      | breakpoint |
      | 320 |
      | 480 |
      | 768 |
      | 1024 |
      | 1280 |
      | 1920 |

  Scenario Outline: View the various pages at various widths
    Given I am at "<screen>"
    Then I take a screenshot with title "<title>"
    Examples:
      | screen | title |
      | home   | Home |
