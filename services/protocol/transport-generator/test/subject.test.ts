import { describe, expect, test } from "bun:test";

import { SubjectTemplate } from "../src/routes/subject.js";

describe("subject templates", () => {
  test("rejects all broker wildcards", () => {
    for (const subject of ["cloud.to.>", "cloud.to.*", "cloud.to.{unknown}"]) {
      expect(() => SubjectTemplate.parse(subject)).toThrow("invalid subject token");
    }
  });

  test("rejects empty and embedded parameter tokens", () => {
    for (const subject of ["cloud..user.{user}", "cloud.to.user-{user}.watch", "cloud.to.{user}.watch."]) {
      expect(() => SubjectTemplate.parse(subject)).toThrow("invalid subject token");
    }
  });

  test("rejects repeated captures", () => {
    expect(() => SubjectTemplate.parse("cloud.{user}.to.{user}")).toThrow(
      "repeated subject parameter {user}",
    );
  });

  test("admits only a final bounded transfer parameter", () => {
    const subject = SubjectTemplate.parse(
      "service.from.{realm}.organization.{organization}.updates.{transfer_id}",
    );
    subject.validateScope("realm", true);
    expect(() => subject.validateScope("realm", false)).toThrow(
      "transfer_id is valid only as the final bounded update token",
    );
    expect(() =>
      SubjectTemplate.parse("service.from.{realm}.organization.{organization}.updates").validateScope(
        "realm",
        true,
      ),
    ).toThrow("bounded updates must end in transfer_id");
  });

  test("permits projection endpoints with a scope subset", () => {
    SubjectTemplate.parse("service.to.{realm}.editor.authoring.state.query").validateScope("realm", false);
  });

  test("rejects captures outside the scope", () => {
    expect(() => SubjectTemplate.parse("cloud.to.{service}").validateScope("user", false)).toThrow(
      "subject parameter service is absent from user scope",
    );
  });

  test("rejects a request missing a required capture", () => {
    const subject = SubjectTemplate.parse("cloud.to.organization.{organization}.members.watch");
    expect(() => subject.validateRequestScope("organization_actor")).toThrow(
      "request subject is missing required user parameter for organization_actor scope",
    );
  });

  test("round trips its manifest spelling", () => {
    const text = "cloud.to.user.{user}.organization.{organization}.watch";
    expect(SubjectTemplate.parse(text).toString()).toBe(text);
    expect(SubjectTemplate.parse(text).parameters()).toEqual(["organization", "user"]);
  });
});
