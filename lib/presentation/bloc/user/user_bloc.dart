import 'package:attendance_app/domain/usecases/user/add_user.dart';
import 'package:attendance_app/domain/usecases/user/get_users.dart';
import 'package:attendance_app/domain/usecases/user/update_user.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:attendance_app/domain/entities/user.dart';

part 'user_event.dart';
part 'user_state.dart';

/// BLoC para gestionar el estado de usuarios
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetUsers getUsers;
  final AddUser addUser;
  final UpdateUser updateUser;

  UserBloc({
    required this.getUsers,
    required this.addUser,
    required this.updateUser,
  }) : super(UserInitial()) {
    // Cargar la lista de usuarios
    on<LoadUsersEvent>(_onLoadUsers);

    // Filtrar usuarios
    on<FilterUsersEvent>(_onFilterUsers);

    // Agregar un nuevo usuario
    on<AddUserEvent>(_onAddUser);

    // Actualizar un usuario existente
    on<UpdateUserEvent>(_onUpdateUser);
  }

  /// Maneja el evento para cargar usuarios
  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    final result = await getUsers(GetUsersParams.all());

    result.fold(
      (failure) => emit(UserError(message: failure.message)),
      (users) => emit(UsersLoaded(users: users)),
    );
  }

  /// Maneja el evento para filtrar usuarios
  Future<void> _onFilterUsers(
    FilterUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    final result = await getUsers(
      GetUsersParams(
        role: event.role,
        isActive: event.isActive,
        searchQuery: event.searchQuery,
      ),
    );

    result.fold(
      (failure) => emit(UserError(message: failure.message)),
      (users) => emit(UsersLoaded(users: users)),
    );
  }

  /// Maneja el evento para agregar un usuario
  Future<void> _onAddUser(
    AddUserEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    final result = await addUser(
      AddUserParams(
        name: event.name,
        email: event.email,
        password: event.password,
        role: event.role,
        phone: event.phone,
        identification: event.identification,
        profilePicture: event.profilePicture,
      ),
    );

    result.fold(
      (failure) => emit(UserError(message: failure.message)),
      (user) async {
        // Recargar la lista de usuarios
        final usersResult = await getUsers(GetUsersParams.all());

        usersResult.fold(
          (failure) => emit(UserError(message: failure.message)),
          (users) => emit(UserAdded(user: user, users: users)),
        );
      },
    );
  }

  /// Maneja el evento para actualizar un usuario
  Future<void> _onUpdateUser(
    UpdateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());

    final result = await updateUser(
      UpdateUserParams(
        id: event.id,
        name: event.name,
        email: event.email,
        role: event.role,
        phone: event.phone,
        identification: event.identification,
        profilePicture: event.profilePicture,
        isActive: event.isActive,
      ),
    );

    result.fold(
      (failure) => emit(UserError(message: failure.message)),
      (user) async {
        // Recargar la lista de usuarios
        final usersResult = await getUsers(GetUsersParams.all());

        usersResult.fold(
          (failure) => emit(UserError(message: failure.message)),
          (users) => emit(UserUpdated(user: user, users: users)),
        );
      },
    );
  }
}
