<?php

namespace Drupal\Tests\module\Unit;

use Drupal\module\Service;
use Drupal\Tests\UnitTestCase;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Group;

#[CoversClass(\Drupal\module\Service::class)]
#[Group('module')]
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
  protected function setUp(): void {
    parent::setUp();

    $this->service = new Service();
  }

  #[DataProvider('numberProvider')]
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
