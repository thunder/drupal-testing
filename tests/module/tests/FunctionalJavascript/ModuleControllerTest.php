<?php

namespace Drupal\Tests\module\FunctionalJavascript;

use Drupal\FunctionalJavascriptTests\WebDriverTestBase;

/**
 * Class ModuleControllerTest.
 *
 * Javascript tests.
 *
 * @group module
 */
class ModuleControllerTest extends WebDriverTestBase {

  /**
   * {@inheritdoc}
   */
  protected static $modules = ['module'];

  /**
   * {@inheritdoc}
   */
  protected $defaultTheme = 'stable';

  /**
   * {@inheritdoc}
   */
  public function setUp() {
    parent::setUp();

    $this->drupalLogin($this->drupalCreateUser([
      'access content',
    ]));
  }

  /**
   * Test enhanced entity revision routes access.
   */
  public function testControllerRoute(): void {
    $this->drupalGet('/module/controller');
    $this->assertSession()->pageTextContains('It works!');
  }

}
