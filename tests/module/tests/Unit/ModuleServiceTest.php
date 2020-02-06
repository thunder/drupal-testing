<?php

namespace Drupal\Tests\module\Unit;

use Drupal\module\Service;
use Drupal\Tests\UnitTestCase;

/**
 * @coversDefaultClass \Drupal\module\Service
 * @group module
 */
class ModuleServiceTest extends UnitTestCase {
  /**
   * The entity permission provider.
   *
   * @var \Drupal\module\Service
   */
  protected $service;

  /**
   * {@inheritdoc}
   */
  protected function setUp() {
    parent::setUp();

    $this->service = new Service();
  }

  /**
   * @covers ::serve
   *
   * @dataProvider numberProvider
   */
  public function testServe($number, $serving): void {
    $this->assertEquals($serving, $this->service->serve($number));
  }

  /**
   * Data provider for testServe().
   *
   * @return array
   *   A list of number and the servings they generate.
   */
  public function numberProvider(): array {
    return [
      [1, 'You have been served a 1'],
    ];
  }

}
