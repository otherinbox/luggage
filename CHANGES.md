#Changes

## 1.2.1

* Protect against trying to UID FETCH an empty list of UIDs. - Ben Hamill

## 1.2.0

* Add `Message#copy_to!`. - Ben Hamill

## 1.1.2

* Remove hidden reliance on ActiveRecord's `#present?` helper. - Ben Hamill

## 1.1.1

* Fix bug when trying to use XOAUTH to authenticate. - Ben Hamill
* Remove several cases of excessive argument type checking. - Ben Hamill

## 1.1.0

* Added `:login` authentication method to `Luggage.new`. - Ben Hamill

## 1.0.0

* Initial release. - Ryan Michael & Eric Pinzur
