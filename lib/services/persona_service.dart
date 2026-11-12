import '../config/api_config.dart';
import '../models/filtros_persona.dart';
import '../models/paginated_response.dart';
import '../models/persona.dart';
import 'api_client.dart';

/// Consultas al catálogo de personas.
class PersonaService {
  PersonaService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// `GET /api/personas/?search=...&page=...`
  Future<PaginatedResponse<Persona>> buscar({
    String? search,
    int page = 1,
    int pageSize = 20,
    int? idEstructura,
    bool? soloActivas,
  }) async {
    final datos = await _client.get(
      ApiConfig.personas,
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'page': page,
        'page_size': pageSize,
        if (idEstructura != null) 'id_estructura': idEstructura,
        if (soloActivas == true) 'baja': false,
      },
    );
    return PaginatedResponse<Persona>.fromJson(datos, Persona.fromJson);
  }

  /// `GET /api/personas/{id}/`
  Future<Persona> detalle(String id) async {
    final datos = await _client.get(ApiConfig.persona(id));
    if (datos is! Map) {
      throw StateError('Respuesta inválida al obtener la persona $id');
    }
    return Persona.fromJson(Map<String, dynamic>.from(datos));
  }

  /// `GET /api/personas/filters/` — estructuras, roles y cargos.
  Future<FiltrosPersona> filtros() async {
    final datos = await _client.get(ApiConfig.personasFiltros);
    if (datos is! Map) return const FiltrosPersona();
    return FiltrosPersona.fromJson(Map<String, dynamic>.from(datos));
  }
}
