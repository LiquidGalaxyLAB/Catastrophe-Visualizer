import 'look_at.dart';

class Flyto {
  LookAt lookAt;

  Flyto(this.lookAt);

  generateFlyto() {
    return 'flytoview=${this.lookAt}';
  }
}
