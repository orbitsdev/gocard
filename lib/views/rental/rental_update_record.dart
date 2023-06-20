import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gocar/utils/helpers/asset.dart';
import 'package:heroicons/heroicons.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gocar/controllers/rental/rental_controller.dart';
import 'package:gocar/models/vehicle.dart';
import 'package:gocar/utils/modal.dart';
import 'package:gocar/utils/themes/app_color.dart';
import 'package:gocar/widgets/h.dart';
import 'package:gocar/widgets/loader_widget.dart';
import 'package:gocar/widgets/v.dart';
import 'package:shimmer/shimmer.dart';

class RentalUpdateRecord extends StatefulWidget {
  Vehicle? vehicle;
  RentalUpdateRecord({
    Key? key,
    this.vehicle,
  }) : super(key: key);

  @override
  _RentalUpdateRecordState createState() => _RentalUpdateRecordState();
}

class _RentalUpdateRecordState extends State<RentalUpdateRecord> {
  final rentController = Get.find<RentalController>();
  late TextEditingController _modelName;
  late TextEditingController _plateNumber;
  late TextEditingController _description;
  late TextEditingController _price;

  final _key = GlobalKey<FormState>();
  final _focusScopeNode = FocusScopeNode();

  late FocusNode _modelNameFocusNode;
  late FocusNode _plateNumberFocusNode;
  late FocusNode _descriptionFocusNode;
  late FocusNode _priceFocusNode;

  File? _image;
  List<File> _images = [];
  late List<String> existing_featured_image;
  List<String> remove_featured = [];

  @override
  void initState() {
    _modelName = TextEditingController(text: widget.vehicle?.model_name ?? '');
    _plateNumber =
        TextEditingController(text: widget.vehicle?.plate_number ?? '');
    _description =
        TextEditingController(text: widget.vehicle?.description ?? '');
    _price =
        TextEditingController(text: widget.vehicle?.price.toString() ?? '0');

    existing_featured_image = widget.vehicle?.featured_image ?? [];

    _modelNameFocusNode = FocusNode();
    _plateNumberFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
    _priceFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    _modelName.dispose();
    _plateNumber.dispose();
    _description.dispose();
    _price.dispose();

    _modelNameFocusNode.dispose();
    _plateNumberFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  final picker = ImagePicker();

  void chooseImages() async {
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _images.addAll(
            pickedFiles.map((pickedFile) => File(pickedFile.path)).toList());
      });
    }
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      setState(() {
        _images.add(File(response.file!.path));
      });
    } else {
      print(response.file);
    }
  }

  void showBottomSheet() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.23,
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  'Select Source',
                  style: TextStyle(fontSize: 18),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      ListTile(
                        onTap: () => chooseImage(ImageSource.camera),
                        leading: HeroIcon(HeroIcons.camera),
                        title: const Text('Camera'),
                      ),
                      ListTile(
                        onTap: () => chooseImage(ImageSource.gallery),
                        leading: HeroIcon(HeroIcons.photo),
                        title: const Text('Gallery'),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  Future<void> chooseImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    Get.back();
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void removeFeaturedImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  _update(BuildContext context) {
    _focusScopeNode.unfocus();

    // Validate the form
    if (_key.currentState!.validate()) {
      if (_image == null) {
        Modal.showToast(context: context, message: 'Cover  image is required');
        return;
      }

      if (_images.length < 3) {
        Modal.showToast(
            context: context,
            message: 'You should have atleast 3 featured image');
        return;
      }

      rentController.updateVehicleInformation(
          context: context,
          model_name: _modelName.text.trim(),
          plate_number: _plateNumber.text.trim(),
          description: _description.text.trim(),
          price: _price.text.trim(),
          cover_image: _image as File,
          featured_image: _images,
          remove_featured: remove_featured,
           vehicle: widget.vehicle as Vehicle,
          );
    }
  }

  void removeExistingFeatured(int index) {
    int total_featured_image = existing_featured_image.length + _images.length;

    if (total_featured_image > 3) {
      setState(() {
        remove_featured.add(existing_featured_image[index]);
        existing_featured_image.removeAt(index);
      });
    } else {
      Modal.showToast(
          context: context,
          message:
              'You must have atleast 3  featured  image. Try adding one to delete the image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New For Rent Car'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Container(
          child: Form(
            key: _key,
            child: FocusScope(
              node: _focusScopeNode,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Model name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(),
                    controller: _modelName,
                    focusNode: _modelNameFocusNode,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Model name is required ';
                      }
                      return null;
                    },
                  ),
                  const H(20),
                  Text(
                    'Rent Price',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(),
                    controller: _price,
                    focusNode: _priceFocusNode,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Price is required ';
                      }
                      return null;
                    },
                  ),
                  const H(20),
                  Text(
                    'Plate Number ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(),
                    controller: _plateNumber,
                    focusNode: _plateNumberFocusNode,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Plate Number is required ';
                      }
                      return null;
                    },
                  ),
                  const V(20),
                  Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    maxLines: 5,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(),
                    controller: _description,
                    focusNode: _descriptionFocusNode,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Discription is required ';
                      }
                      return null;
                    },
                  ),
                  const V(20),
                  Text(
                    'Cover Image',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const V(10),
                  Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: showBottomSheet,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _image != null
                            ? Image.file(
                                width: double.infinity,
                                _image!,
                                fit: BoxFit.cover,
                                errorBuilder: (BuildContext context,
                                    Object exception, StackTrace? stackTrace) {
                                  // Handle image load errors here
                                  return Center(
                                      child: Text('Error loading image'));
                                },
                              )
                            : widget.vehicle?.cover_image != null
                                ? CachedNetworkImage(
                                    imageUrl: widget.vehicle?.cover_image ??
                                        Asset.avatarDefault,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Shimmer.fromColors(
                                      child: Container(
                                        color: Colors.grey[300],
                                      ),
                                      baseColor: Colors.grey[300]!,
                                      highlightColor: Colors.grey[100]!,
                                      period:
                                          const Duration(milliseconds: 1500),
                                    ),
                                  )
                                : Center(
                                    child: Icon(Icons.image),
                                  ),
                      ),
                    ),
                  ),
                  const V(20),
                  if (existing_featured_image.length > 0)
                    Column(
                      children: [
                        Text(
                          'Existing featured image',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const V(10),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            // Handle tap here
                          },
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: List.generate(
                                existing_featured_image.length,
                                (index) => Stack(
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: CachedNetworkImage(
                                              imageUrl: existing_featured_image[
                                                  index],
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Shimmer.fromColors(
                                                child: Container(
                                                    color: Colors.grey[300]),
                                                baseColor: Colors.grey[300]!,
                                                highlightColor:
                                                    Colors.grey[100]!,
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Icon(Icons.error),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              setState(() {
                                                removeExistingFeatured(index);
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                              ),
                                              child:
                                                  Icon(Icons.close, size: 18),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )),
                          ),
                        )
                      ],
                    ),
                  const V(20),
                  Text(
                    'Featured Images',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const V(10),
                  Container(
                    height: 215,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        // Handle tap here
                      },
                      child: GridView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _images.length + 1,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 5,
                          crossAxisSpacing: 5,
                        ),
                        itemBuilder: (context, index) {
                          return index == 0
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Center(
                                    child: IconButton(
                                      onPressed: chooseImages,
                                      icon: Icon(Icons.add),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 1,
                                    ),
                                  ),
                                  child: Stack(
                                      fit: StackFit.expand,
                                      clipBehavior: Clip.none,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          child: Image.file(
                                            _images[index - 1],
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 2,
                                          right: 3,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () =>
                                                removeFeaturedImage(index - 1),
                                            child: ClipOval(
                                              child: Container(
                                                width: 34,
                                                height: 34,
                                                padding: EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            100),
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                    border: Border.all(
                                                        width: 2,
                                                        color: Colors.white)),
                                                child: Center(
                                                  child: HeroIcon(
                                                    HeroIcons.xMark,
                                                    style: HeroIconStyle.solid,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ]),
                                );
                        },
                      ),
                    ),
                  ),
                  GetBuilder<RentalController>(builder: (controller) {
                    return SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => controller.isCreating.value
                            ? null
                            : _update(context),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          primary: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: controller.isCreating.value
                            ? LoaderWidget(
                                color: Colors.white,
                              )
                            : const Text(
                                "Update",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  }),
                  const V(20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
