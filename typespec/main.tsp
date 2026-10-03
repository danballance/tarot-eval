import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

using Http;
using OpenAPI;

@service(#{ title: "Tarot Reading API" })
@info(#{ version: "1.0.0" })
namespace TarotReadingAPI;

@summary("AgentResponse")
model AgentResponse {
  positionalResponses: PositionalResponses;
  @minLength(1) @summary("Summary") summary: string;
}

/**
 * Represents a single card from the reading.
 *
 * Args:
 *     code_name (str)   : Code name for card as seen in file system,
 *                         i.e. 0_the_fool, ace_cups, 4_swords
 *     display_name (str): Name to display via GUI, i.e.
 *                         The Fool, Ace of Cups, Four of Swords
 *     description (str) : Text description of the card's appearance.
 *     meaning (str)     : The meaning of the card within the reading.
 *     meaning_summary (str): A shorter summary of the card's meaning for quick readings.
 */
@summary("Card")
model Card {
  @minLength(1) @summary("Codename") codeName: string;
  @minLength(1) @summary("Displayname") displayName: string;
  @minLength(1) @summary("Description") description: string;
  @minLength(1) @summary("Meaning") meaning: string;
  @minLength(1) @summary("Meaningsummary") meaningSummary: string;
}

/** Enum representing the depth of a tarot reading. */
@summary("Depth")
enum Depth {
  quick,
  detailed,
}

/** The code name of a tarot deck. */
@summary("DeckName")
enum DeckName {
  fantasy,
  `modern-traditional`,
  rainbow,
}

@summary("ValidationError")
model ValidationError {
  @summary("Location") loc: (string | integer)[];
  @summary("Message") msg: string;
  @summary("Error Type") type: string;
}

@summary("HTTPValidationError")
@error
model HTTPValidationError {
  @summary("Detail") detail?: ValidationError[];
}

/** The generated Reading */
model ReadingCreatedResponse {
  @statusCode statusCode: 200;
  @body body: Reading;
}

/** A collection of Readings */
model ReadingListResponse {
  @statusCode statusCode: 200;
  @body body: Reading[];
}

/** The fetched reading */
model ReadingResponse {
  @statusCode statusCode: 200;
  @body body: Reading;
}

/** The reading was deleted */
model ReadingDeletedResponse {
  @statusCode statusCode: 204;
}

/** Validation Error */
model ValidationErrorResponse {
  @statusCode statusCode: 422;
  @body body: HTTPValidationError;
}

@summary("PositionalResponses")
model PositionalResponses {
  @summary("Past") past: string;
  @summary("Present") present: string;
  @summary("Future") future: string;
}

/**
 * Model for a generated tarot reading, including its persistent ID.
 *
 * Args:
 *     id (str | None): The unique ID assigned by the persistence layer (e.g., Firestore document ID). Defaults to None.
 *     user_id (str): The unique ID of the user who requested the reading (from Clerk).
 *     timestamp (datetime): The timestamp when the reading was created.
 *     depth (Depth): The depth of the reading.
 *     question (str): The question asked by the enquirer.
 *     deck_name (DeckName): The code name of the deck used for the reading.
 *     spread (SpreadCompleted): The cards dealt in their positions.
 *     agent_response (AgentResponse): The LLM's structured interpretation.
 */
@summary("Reading")
model Reading {
  @summary("Id") id?: string;
  @minLength(1) @summary("Userid") userId: string;
  @summary("Timestamp") timestamp: utcDateTime;
  depth: Depth;
  @minLength(1) @summary("Question") question: string;
  @summary("Deckname") deckName: DeckName;
  spread: SpreadCompleted;
  agentResponse: AgentResponse;
}

/**
 * Request model for creating a tarot reading.
 *
 * Args:
 *     depth (Depth): The depth of the reading.
 *     question (str): The question asked by the enquirer.
 *     deck_name (DeckName): The code name of the deck to use for the reading.
 */
@summary("ReadingRequest")
model ReadingCreateRequest {
  depth?: Depth = Depth.detailed;
  @minLength(1) @summary("Question") question: string;
  @summary("Deckname") deckName: DeckName;
}

/** A three-card spread after each position has been assigned a card. */
@summary("SpreadCompleted")
model SpreadCompleted {
  ...Record<never>;
  past: Card;
  present: Card;
  future: Card;
}

@route("/v1/readings")
@post
@summary("Create a new tarot Reading")
op `readings-create`(@body body: ReadingCreateRequest):
  | ReadingCreatedResponse
  | ValidationErrorResponse;

@route("/v1/readings/user_id/{user_id}")
@get
@summary("List a User's Readings")
op `readings-list`(
  @summary("User Id") @path user_id: string,
  @summary("Limit") @query(#{ explode: true }) limit?: integer,
): ReadingListResponse | ValidationErrorResponse;

@route("/v1/readings/user_id/{user_id}/id/{reading_id}")
@delete
@summary("Delete a single User's Reading")
op `reading-delete`(
  @summary("User Id") @path user_id: string,
  @summary("Reading Id") @path reading_id: string,
): ReadingDeletedResponse | ValidationErrorResponse;

@route("/v1/readings/user_id/{user_id}/id/{reading_id}")
@get
@summary("Read a single User's Reading")
op `reading-read`(
  @summary("User Id") @path user_id: string,
  @summary("Reading Id") @path reading_id: string,
): ReadingResponse | ValidationErrorResponse;
