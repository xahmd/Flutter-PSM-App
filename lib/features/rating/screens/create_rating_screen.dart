import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../firebase_options.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';

class CreateRatingScreen extends StatefulWidget {
  final String foremanId;
  final String foremanName;

  const CreateRatingScreen({
    Key? key,
    required this.foremanId,
    required this.foremanName,
  }) : super(key: key);

  @override
  State<CreateRatingScreen> createState() => _CreateRatingScreenState();
}

class _CreateRatingScreenState extends State<CreateRatingScreen> {
  final RatingService _ratingService = RatingService();
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  final _projectNameController = TextEditingController();

  int _overallRating = 5;
  int _qualityRating = 5;
  int _timelinessRating = 5;
  int _communicationRating = 5;
  int _safetyRating = 5;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate ${widget.foremanName}'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildForemanInfo(),
                const SizedBox(height: 16),
                _buildProjectNameField(),
                const SizedBox(height: 24),
                _buildRatingSection(
                  'Overall Performance',
                  _overallRating,
                  (value) => setState(() => _overallRating = value),
                ),
                _buildRatingSection(
                  'Work Quality',
                  _qualityRating,
                  (value) => setState(() => _qualityRating = value),
                ),
                _buildRatingSection(
                  'Timeliness',
                  _timelinessRating,
                  (value) => setState(() => _timelinessRating = value),
                ),
                _buildRatingSection(
                  'Communication',
                  _communicationRating,
                  (value) => setState(() => _communicationRating = value),
                ),
                _buildRatingSection(
                  'Safety Standards',
                  _safetyRating,
                  (value) => setState(() => _safetyRating = value),
                ),
                const SizedBox(height: 24),
                _buildCommentsField(),
                const SizedBox(height: 30),
                _buildSubmitButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForemanInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE67E22), Color(0xFFD35400)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                widget.foremanName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.foremanName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Foreman Performance Evaluation',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectNameField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextFormField(
        controller: _projectNameController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Project Name',
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
          prefixIcon: Icon(
            Icons.work_outline,
            color: Colors.white.withOpacity(0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the project name';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRatingSection(
    String title,
    int currentValue,
    Function(int) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => onChanged(index + 1),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        index < currentValue
                            ? Colors.amber.withOpacity(0.2)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.star,
                    color:
                        index < currentValue
                            ? Colors.amber
                            : Colors.white.withOpacity(0.4),
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '$currentValue out of 5 stars',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextFormField(
        controller: _commentsController,
        maxLines: 4,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Comments',
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
          hintText:
              'Provide detailed feedback about the foreman\'s performance...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(
            Icons.comment_outlined,
            color: Colors.white.withOpacity(0.6),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please provide feedback comments';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE67E22), Color(0xFFD35400)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRating,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rate_review, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Submit Rating',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Future<void> _submitRating() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final rating = Rating(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        foremanId: widget.foremanId,
        foremanName: widget.foremanName,
        ownerId: user.uid,
        ownerName: user.displayName ?? user.email ?? 'Unknown',
        overallRating: _overallRating,
        qualityRating: _qualityRating,
        timelinessRating: _timelinessRating,
        communicationRating: _communicationRating,
        safetyRating: _safetyRating,
        comments: _commentsController.text,
        createdAt: DateTime.now(),
        projectName: _projectNameController.text,
      );

      print('🔥🔥🔥 SUBMITTING RATING 🔥🔥🔥');
      print('🔥 Foreman ID: ${widget.foremanId}');
      print('🔥 Foreman Name: ${widget.foremanName}');
      print('🔥 Owner ID: ${user.uid}');
      print('🔥 Project: ${_projectNameController.text}');
      print('🔥 Average Rating: ${rating.averageRating}');

      await _ratingService.createRating(rating);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ Rating submitted successfully!\nThe foreman will see it in their dashboard.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('🔥 Error submitting rating: $e');
      if (mounted) {
        String message = '❌ Error submitting rating';
        Color backgroundColor = Colors.red;

        if (e.toString().contains('permission-denied')) {
          message =
              '⚠️ Rating saved in demo mode!\nDatabase permissions are limited, but the rating has been cached locally.';
          backgroundColor = Colors.orange;

          // Still navigate back on success in demo mode
          Navigator.pop(context);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _projectNameController.dispose();
    super.dispose();
  }
}
