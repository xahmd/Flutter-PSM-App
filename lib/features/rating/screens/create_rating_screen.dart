import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rating.dart';
import '../services/rating_service.dart';

class CreateRatingScreen extends StatefulWidget {
  final String workerId;
  final String workerName;

  const CreateRatingScreen({
    Key? key,
    required this.workerId,
    required this.workerName,
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
  int _technicalRating = 5;
  int _timelinessRating = 5;
  int _communicationRating = 5;
  int _safetyRating = 5;

  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate Worker: ${widget.workerName}'),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
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
                _buildWorkerInfo(),
                const SizedBox(height: 24),
                _buildProjectNameField(),
                const SizedBox(height: 24),
                _buildRatingSection('Overall Performance', _overallRating, (value) => setState(() => _overallRating = value)),
                _buildRatingSection('Technical Skills', _technicalRating, (value) => setState(() => _technicalRating = value)),
                _buildRatingSection('Time Management', _timelinessRating, (value) => setState(() => _timelinessRating = value)),
                _buildRatingSection('Workshop Communication', _communicationRating, (value) => setState(() => _communicationRating = value)),
                _buildRatingSection('Safety Compliance', _safetyRating, (value) => setState(() => _safetyRating = value)),
                const SizedBox(height: 24),
                _buildCommentsField(),
                const SizedBox(height: 30),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerInfo() {
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
            child: const Icon(
              Icons.engineering,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.workerName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Workshop Performance Evaluation',
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
    return TextFormField(
      controller: _projectNameController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Project Name',
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter project name';
        }
        return null;
      },
    );
  }

  Widget _buildRatingSection(String title, int currentValue, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              onPressed: () => onChanged(index + 1),
              icon: Icon(
                Icons.star,
                color: index < currentValue ? Colors.amber : Colors.grey,
                size: 30,
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCommentsField() {
    return TextFormField(
      controller: _commentsController,
      maxLines: 4,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Comments',
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        hintText: 'Provide additional feedback...',
        hintStyle: TextStyle(color: Colors.white30),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please provide comments';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRating,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Submit Rating', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _submitRating() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final rating = Rating(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        workerId: widget.workerId,
        workerName: widget.workerName,
        ownerId: user.uid,
        ownerName: user.displayName ?? user.email ?? 'Unknown',
        overallRating: _overallRating,
        technicalRating: _technicalRating,
        timelinessRating: _timelinessRating,
        communicationRating: _communicationRating,
        safetyRating: _safetyRating,
        comments: _commentsController.text,
        createdAt: DateTime.now(),
        projectName: _projectNameController.text,
      );

      await _ratingService.createRating(rating);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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