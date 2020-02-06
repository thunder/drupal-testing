<?php

namespace Drupal\module;

/**
 * The Service class.
 *
 * @package Drupal\module
 */
class Service {

  /**
   * Serve the service.
   *
   * @param int $number
   *   A number we do things with.
   *
   * @return string
   *   Information based on the given number.
   */
  public function serve(int $number): string {
    return 'You have been served a ' . $number;
  }

}
