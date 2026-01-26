import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/admin_models.dart';
import '../../../services/admin_service.dart';
import '../../../services/media_upload_service.dart';

class LessonFormScreen extends StatefulWidget {
  final Lesson? lesson;

  const LessonFormScreen({super.key, this.lesson});

  @override
  State<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends State<LessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _language = 'Amharic';
  String? _categoryId;
  String? _category;
  int _difficulty = 1;
  String _status = 'draft';
  int _estimatedMinutes = 5;
  
  List<Exercise> _exercises = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.lesson != null) {
      _loadLesson();
    }
  }

  void _loadLesson() {
    final lesson = widget.lesson!;
    _titleController.text = lesson.title;
    _descriptionController.text = lesson.description ?? '';
    _language = lesson.language;
    _categoryId = lesson.categoryId;
    _category = lesson.category;
    _difficulty = lesson.difficulty;
    _status = lesson.status;
    _estimatedMinutes = lesson.estimatedMinutes;
    _exercises = lesson.exercises ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadFullLesson() async {
    if (widget.lesson == null) return;
    
    setState(() => _isLoading = true);
    try {
      final fullLesson = await AdminService.getLesson(widget.lesson!.id);
      setState(() {
        _exercises = fullLesson.exercises ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load lesson: $e')),
        );
      }
    }
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'language': _language,
        'category_id': _categoryId,
        'category': _category,
        'difficulty': _difficulty,
        'status': _status,
        'estimated_minutes': _estimatedMinutes,
      };

      Lesson savedLesson;
      if (widget.lesson != null) {
        savedLesson = await AdminService.updateLesson(widget.lesson!.id, data);
      } else {
        savedLesson = await AdminService.createLesson(data);
      }

      // Save exercises
      for (final exercise in _exercises) {
        await AdminService.saveExercise({
          'id': exercise.id == 'new' ? null : exercise.id,
          'lesson_id': savedLesson.id,
          'type': exercise.type,
          'prompt': exercise.prompt,
          'options': exercise.options,
          'correct_answer': exercise.correctAnswer,
          'points': exercise.points,
          'media_url': exercise.mediaUrl,
          'order_index': exercise.orderIndex,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lesson saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save lesson: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _addExercise() {
    setState(() {
      _exercises.add(Exercise(
        id: 'new',
        lessonId: widget.lesson?.id ?? '',
        type: 'multiple-choice',
        prompt: '',
        correctAnswer: '',
        points: 1,
        orderIndex: _exercises.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    });
  }

  void _removeExercise(int index) {
    setState(() {
      final exercise = _exercises[index];
      if (exercise.id != 'new') {
        AdminService.deleteExercise(exercise.id).catchError((e) {
          debugPrint('Error deleting exercise: $e');
        });
      }
      _exercises.removeAt(index);
      // Reorder remaining exercises
      for (int i = 0; i < _exercises.length; i++) {
        _exercises[i] = _exercises[i].copyWith(orderIndex: i);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson == null ? 'Create Lesson' : 'Edit Lesson'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveLesson,
              tooltip: 'Save Lesson',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        label: Text('Title'),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        label: Text('Description'),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _language,
                            decoration: const InputDecoration(
                              label: Text('Language'),
                              border: OutlineInputBorder(),
                            ),
                            items: ['Amharic', 'Tigrinya', 'Afaan Oromo']
                                .map((lang) => DropdownMenuItem(
                                      value: lang,
                                      child: Text(lang),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _language = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _difficulty,
                            decoration: const InputDecoration(
                              label: Text('Difficulty'),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('Beginner')),
                              DropdownMenuItem(value: 2, child: Text('Intermediate')),
                              DropdownMenuItem(value: 3, child: Text('Advanced')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _difficulty = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              label: Text('Status'),
                              border: OutlineInputBorder(),
                            ),
                            items: ['draft', 'published', 'archived']
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status.toUpperCase()),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _status = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _estimatedMinutes.toString(),
                            decoration: const InputDecoration(
                              label: Text('Estimated Minutes'),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _estimatedMinutes = int.tryParse(value) ?? 5;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Exercises Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Exercises (${_exercises.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        FilledButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Exercise'),
                          onPressed: _addExercise,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._exercises.asMap().entries.map((entry) {
                      final index = entry.key;
                      final exercise = entry.value;
                      return _buildExerciseCard(exercise, index);
                    }),
                    if (_exercises.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text('No exercises yet. Add one to get started.'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text('Exercise ${index + 1}: ${exercise.type}'),
        subtitle: Text(exercise.prompt.isEmpty ? 'No prompt' : exercise.prompt),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeExercise(index),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildExerciseForm(exercise, index),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseForm(Exercise exercise, int index) {
    final promptController = TextEditingController(text: exercise.prompt);
    final correctAnswerController = TextEditingController(text: exercise.correctAnswer);
    final pointsController = TextEditingController(text: exercise.points.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: exercise.type,
          decoration: const InputDecoration(
            label: Text('Exercise Type'),
            border: OutlineInputBorder(),
          ),
          items: [
            'multiple-choice',
            'listen-repeat',
            'translate',
            'fill-blank',
            'matching',
            'reorder',
          ].map((type) => DropdownMenuItem(
                value: type,
                child: Text(type.replaceAll('-', ' ').toUpperCase()),
              )).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _exercises[index] = exercise.copyWith(type: value);
              });
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: promptController,
          decoration: const InputDecoration(
            label: Text('Prompt'),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (value) {
            setState(() {
              _exercises[index] = exercise.copyWith(prompt: value);
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: correctAnswerController,
          decoration: const InputDecoration(
            label: Text('Correct Answer'),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _exercises[index] = exercise.copyWith(correctAnswer: value);
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: pointsController,
                decoration: const InputDecoration(
                  label: Text('Points'),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final points = int.tryParse(value) ?? 1;
                  setState(() {
                    _exercises[index] = exercise.copyWith(points: points);
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Media'),
                onPressed: () => _uploadMediaForExercise(index),
              ),
            ),
          ],
        ),
        if (exercise.mediaUrl != null) ...[
          const SizedBox(height: 8),
          Text('Media: ${exercise.mediaUrl}'),
        ],
      ],
    );
  }

  Future<void> _uploadMediaForExercise(int index) async {
    try {
      final result = await MediaUploadService.pickAndUpload(
        bucketName: 'audio',
        fileType: FileType.any,
      );

      if (result != null && mounted) {
        setState(() {
          _exercises[index] = _exercises[index].copyWith(
            mediaUrl: result['signed_url'] as String,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload media: $e')),
        );
      }
    }
  }
}

