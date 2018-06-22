# Examples

## csdl-16.1

This is the [Products and Categories Example](http://docs.oasis-open.org/odata/odata-csdl-xml/v4.01/cs01/odata-csdl-xml-v4.01-cs01.html#sec_ProductsandCategoriesExample) from the [OData CSDL XML specification](http://docs.oasis-open.org/odata/odata-csdl-xml/v4.01/odata-csdl-xml-v4.01.html).

File | Description
-----|------------
[csdl-16.1.xml](csdl-16.1.xml) | CSDL XML
[csdl-16.1.schema.json](csdl-16.1.schema.json) | JSON Schema generated from CSDL XML
[csdl-16.1-Categories.json](csdl-16.1-Categories.json) | Response for `GET Categories` with three entities
[csdl-16.1-Categories-empty.json](csdl-16.1-Categories-empty.json) | Empty response for `GET Categories`
[csdl-16.1-Categories-fail.json](csdl-16.1-Categories-fail.json) | Invalid response for `GET Categories` - no `value` property in outermost object
[csdl-16.1-Category.json](csdl-16.1-Category.json) | Response for `GET Categories(1)?$expand=Products($expand=Supplier($expand=Products($select=ID)))`
[csdl-16.1-Category-projected.json](csdl-16.1-Category-projected.json) | Response for `GET Categories(1)?$expand=Products($expand=Supplier($expand=Products($select=ID)))` with specific context URL
[csdl-16.1-Category-fail.json](csdl-16.1-Category-fail.json) | Invalid response for `GET Categories(1)?$expand=Products($expand=Supplier($expand=Products($select=ID)))` - wrong data type for `ID` of innermost nested product
[csdl-16.1-MainSupplier.json](csdl-16.1-MainSupplier.json) | Response for `GET MainSupplier` singleton
[csdl-16.1-Product.json](csdl-16.1-Product.json) | Response for `GET Product('WONDER01')?$expand=Category,Supplier`

## TripPin

The [TripPin reference service](http://services.odata.org/TripPinRESTierService/(S(g1oafwlrmrrsxbqyul33p15y))/) from www.odata.org.

File | Description
-----|------------
[TripPin.xml](TripPin.xml) | CSDL XML
[TripPin.schema.json](TripPin.schema.json) | JSON Schema generated from CSDL XML


## ExampleService

A more elaborate example

File | Description
-----|------------
[ExampleService.xml](ExampleService.xml) | CSDL XML
[ExampleService.schema.json](ExampleService.schema.json) | JSON Schema generated from CSDL XML


## miscellaneous

A collection of examples from the [OData CSDL XML specification](http://docs.oasis-open.org/odata/odata-csdl-xml/v4.01/odata-csdl-xml-v4.01.html)

File | Description
-----|------------
[miscellaneous.xml](miscellaneous.xml) | CSDL XML
[miscellaneous.schema.json](miscellaneous.schema.json) | JSON Schema generated from CSDL XML

## miscellaneous2

More examples from the [OData CSDL XML specification](http://docs.oasis-open.org/odata/odata-csdl-xml/v4.01/odata-csdl-xml-v4.01.html)

File | Description
-----|------------
[miscellaneous2.xml](miscellaneous2.xml) | CSDL XML
[miscellaneous2.schema.json](miscellaneous2.schema.json) | JSON Schema generated from CSDL XML