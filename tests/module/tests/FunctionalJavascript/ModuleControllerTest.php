<?php

namespace Drupal\Tests\module\FunctionalJavascript;

use Drupal\FunctionalJavascriptTests\WebDriverTestBase;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\RunTestsInSeparateProcesses;

/**
 * Class ModuleControllerTest.
 *
 * Javascript tests.
 */
#[Group('module')]
#[RunTestsInSeparateProcesses]
class ModuleControllerTest extends WebDriverTestBase {

  /**
   * {@inheritdoc}
   */
  protected static $modules = ['module'];

  /**
   * {@inheritdoc}
   */
  protected $defaultTheme = 'stark';

  /**
   * {@inheritdoc}
   */
  public function setUp(): void {
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
