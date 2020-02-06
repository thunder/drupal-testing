<?php

namespace Drupal\module\Controller;

use Drupal\Core\Controller\ControllerBase;

/**
 * Returns responses for module routes.
 */
class ModuleController extends ControllerBase {

  /**
   * Builds the response.
   */
  public function build() {

    $build['content'] = [
      '#type' => 'item',
      '#markup' => $this->t('It works!'),
    ];

    return $build;
  }

}
